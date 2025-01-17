const std = @import("std");

// 1. 线程安全的计数器
const AtomicCounter = struct {
    value: std.atomic.Value(i32) = std.atomic.Value(i32).init(0),

    pub fn increment(self: *AtomicCounter) void {
        _ = self.value.fetchAdd(1, .monotonic);
    }

    pub fn decrement(self: *AtomicCounter) void {
        _ = self.value.fetchSub(1, .monotonic);
    }

    pub fn get(self: *const AtomicCounter) i32 {
        return self.value.load(.monotonic);
    }
};

// 2. 信道（Channel）实现
fn Channel(comptime T: type) type {
    return struct {
        const Self = @This();
        const Queue = std.fifo.LinearFifo(T, .{ .Dynamic = {} });

        mutex: std.Thread.Mutex = .{},
        queue: Queue,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .queue = Queue.init(allocator),
                .allocator = allocator,
            };
        }

        pub fn send(self: *Self, value: T) !void {
            self.mutex.lock();
            defer self.mutex.unlock();
            try self.queue.writeItem(value);
        }

        pub fn receive(self: *Self) !T {
            self.mutex.lock();
            defer self.mutex.unlock();
            if (self.queue.readItem()) |item| {
                return item;
            }
            return error.Empty;
        }

        pub fn deinit(self: *Self) void {
            self.queue.deinit();
        }
    };
}

// 3. 工作池
const WorkerPool = struct {
    const TaskFn = struct {
        fn_ptr: *const fn (usize, *anyopaque) void,
        arg: *anyopaque,
    };
    const TaskChannel = Channel(TaskFn);

    threads: []std.Thread,
    tasks: TaskChannel,
    allocator: std.mem.Allocator,
    running: std.atomic.Value(bool),

    pub fn init(allocator: std.mem.Allocator, num_threads: usize) !WorkerPool {
        var pool = WorkerPool{
            .threads = try allocator.alloc(std.Thread, num_threads),
            .tasks = TaskChannel.init(allocator),
            .allocator = allocator,
            .running = std.atomic.Value(bool).init(true),
        };

        // 创建工作线程
        for (0..num_threads) |i| {
            pool.threads[i] = try std.Thread.spawn(.{}, workerThread, .{ &pool, i });
        }

        return pool;
    }

    fn workerThread(pool: *WorkerPool, thread_id: usize) void {
        while (pool.running.load(.monotonic)) {
            // 使用超时机制，避免永久阻塞
            if (pool.tasks.receive()) |task| {
                task.fn_ptr(thread_id, task.arg);
            } else |_| {
                // 如果没有任务，短暂休眠后继续
                std.time.sleep(std.time.ns_per_ms * 10);
            }
        }
    }

    pub fn submit(self: *WorkerPool, task: *const fn (usize, *anyopaque) void, arg: *anyopaque) !void {
        if (!self.running.load(.monotonic)) return error.PoolStopped;
        try self.tasks.send(TaskFn{
            .fn_ptr = task,
            .arg = arg,
        });
    }

    pub fn stop(self: *WorkerPool) void {
        // 先标记停止
        self.running.store(false, .monotonic);
        // 等待所有线程完成
        for (self.threads) |thread| {
            thread.join();
        }
        // 清理资源
        self.tasks.deinit();
        self.allocator.free(self.threads);
    }
};

// 4. 并发安全的哈希映射
fn ConcurrentHashMap(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();
        const Map = if (K == []const u8) std.StringHashMap(V) else std.AutoHashMap(K, V);

        mutex: std.Thread.Mutex = .{},
        map: Map,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .map = Map.init(allocator),
                .allocator = allocator,
            };
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            self.mutex.lock();
            defer self.mutex.unlock();
            try self.map.put(key, value);
        }

        pub fn get(self: *Self, key: K) ?V {
            self.mutex.lock();
            defer self.mutex.unlock();
            return self.map.get(key);
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }
    };
}

// 5. 条件变量实现
const CondVar = struct {
    mutex: std.Thread.Mutex = .{},
    cond: std.Thread.Condition = .{},
    predicate: bool = false,

    pub fn wait(self: *CondVar) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        while (!self.predicate) {
            self.cond.wait(&self.mutex);
        }
        self.predicate = false;
    }

    pub fn signal(self: *CondVar) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.predicate = true;
        self.cond.signal();
    }
};

// 6. 生产者-消费者队列
fn BoundedQueue(comptime T: type) type {
    return struct {
        const Self = @This();
        const Queue = std.fifo.LinearFifo(T, .{ .Dynamic = {} });

        mutex: std.Thread.Mutex = .{},
        not_full: std.Thread.Condition = .{},
        not_empty: std.Thread.Condition = .{},
        queue: Queue,
        capacity: usize,

        pub fn init(allocator: std.mem.Allocator, capacity: usize) Self {
            return Self{
                .queue = Queue.init(allocator),
                .capacity = capacity,
            };
        }

        pub fn produce(self: *Self, item: T) !void {
            self.mutex.lock();
            defer self.mutex.unlock();

            while (self.queue.readableLength() >= self.capacity) {
                self.not_full.wait(&self.mutex);
            }

            try self.queue.writeItem(item);
            self.not_empty.signal();
        }

        pub fn consume(self: *Self) !T {
            self.mutex.lock();
            defer self.mutex.unlock();

            while (self.queue.readableLength() == 0) {
                self.not_empty.wait(&self.mutex);
            }

            const item = self.queue.readItem().?;
            self.not_full.signal();
            return item;
        }

        pub fn deinit(self: *Self) void {
            self.queue.deinit();
        }
    };
}

// 7. 信号量实现
const Semaphore = struct {
    mutex: std.Thread.Mutex = .{},
    cond: std.Thread.Condition = .{},
    count: usize,

    pub fn init(initial_count: usize) Semaphore {
        return Semaphore{
            .count = initial_count,
        };
    }

    pub fn acquire(self: *Semaphore) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        while (self.count == 0) {
            self.cond.wait(&self.mutex);
        }
        self.count -= 1;
    }

    pub fn release(self: *Semaphore) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.count += 1;
        self.cond.signal();
    }
};

// 8. 读写锁实现
const RwLock = struct {
    mutex: std.Thread.Mutex = .{},
    read_cond: std.Thread.Condition = .{},
    write_cond: std.Thread.Condition = .{},
    readers: usize = 0,
    writers: usize = 0,
    write_waiters: usize = 0,

    pub fn readLock(self: *RwLock) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        while (self.writers > 0 or self.write_waiters > 0) {
            self.read_cond.wait(&self.mutex);
        }
        self.readers += 1;
    }

    pub fn readUnlock(self: *RwLock) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.readers -= 1;
        if (self.readers == 0) {
            self.write_cond.signal();
        }
    }

    pub fn writeLock(self: *RwLock) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.write_waiters += 1;
        while (self.readers > 0 or self.writers > 0) {
            self.write_cond.wait(&self.mutex);
        }
        self.write_waiters -= 1;
        self.writers += 1;
    }

    pub fn writeUnlock(self: *RwLock) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.writers -= 1;
        if (self.write_waiters > 0) {
            self.write_cond.signal();
        } else {
            self.read_cond.broadcast();
        }
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try stdout.print("\n=== Zig 并发特性 ===\n", .{});

    // 1. 原子计数器测试
    {
        var counter = AtomicCounter{};
        counter.increment();
        counter.increment();
        try stdout.print("原子计数器值: {d}\n", .{counter.get()});
    }

    // 2. 信道测试
    {
        var channel = Channel(i32).init(allocator);
        defer channel.deinit();

        try channel.send(42);
        const value = try channel.receive();
        try stdout.print("信道接收值: {d}\n", .{value});
    }

    // 3. 工作池测试
    {
        var pool = try WorkerPool.init(allocator, 4);
        defer pool.stop();

        var result = AtomicCounter{};
        const result_ptr = @as(*anyopaque, @ptrCast(&result));

        // 提交并发任务
        try pool.submit(struct {
            fn task(thread_id: usize, arg: *anyopaque) void {
                _ = thread_id;
                const counter = @as(*AtomicCounter, @ptrCast(@alignCast(arg)));
                counter.increment();
            }
        }.task, result_ptr);

        // 等待一段时间
        std.time.sleep(std.time.ns_per_ms * 100);

        try stdout.print("工作池任务完成，结果: {d}\n", .{result.get()});
    }

    // 4. 并发哈希映射测试
    {
        var map = ConcurrentHashMap([]const u8, i32).init(allocator);
        defer map.deinit();

        try map.put("hello", 42);
        const value = map.get("hello");
        try stdout.print("并发哈希映射值: {?d}\n", .{value});
    }

    // 5. 条件变量测试
    {
        var done = AtomicCounter{};

        const thread = try std.Thread.spawn(.{}, struct {
            fn thread_fn(counter: *AtomicCounter) void {
                std.time.sleep(std.time.ns_per_ms * 100);
                counter.increment();
            }
        }.thread_fn, .{&done});

        while (done.get() == 0) {
            std.time.sleep(std.time.ns_per_ms * 10);
        }
        thread.join();
        try stdout.print("条件变量测试完成\n", .{});
    }

    // 6. 生产者-消费者测试
    {
        var queue = BoundedQueue(i32).init(allocator, 5);
        defer queue.deinit();

        try queue.produce(42);
        const value = try queue.consume();
        try stdout.print("生产者-消费者队列测试: {d}\n", .{value});
    }

    // 7. 信号量测试
    {
        var sem = Semaphore.init(1);
        sem.acquire();
        sem.release();
        try stdout.print("信号量测试完成\n", .{});
    }

    // 8. 读写锁测试
    {
        var rwlock = RwLock{};
        var shared_data: i32 = 0;

        const ThreadContext = struct {
            lock: *RwLock,
            data: *i32,
        };

        const ctx = ThreadContext{
            .lock = &rwlock,
            .data = &shared_data,
        };

        // 读取线程
        const reader_thread = try std.Thread.spawn(.{}, struct {
            fn thread_fn(context: ThreadContext) void {
                context.lock.readLock();
                defer context.lock.readUnlock();
                std.time.sleep(std.time.ns_per_ms * 10);
            }
        }.thread_fn, .{ctx});

        // 写入线程
        const writer_thread = try std.Thread.spawn(.{}, struct {
            fn thread_fn(context: ThreadContext) void {
                context.lock.writeLock();
                defer context.lock.writeUnlock();
                context.data.* += 1;
            }
        }.thread_fn, .{ctx});

        reader_thread.join();
        writer_thread.join();
        try stdout.print("读写锁测试完成，共享数据: {d}\n", .{shared_data});
    }

    try stdout.print("\n=== 并发特性演示结束 ===\n", .{});
}

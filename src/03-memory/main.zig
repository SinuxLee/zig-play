const std = @import("std");

// 1. 基本指针操作
fn pointerBasics() !void {
    const stdout = std.io.getStdOut().writer();

    // 基本变量和指针
    var number: i32 = 42;
    const ptr = &number; // 获取number的指针

    try stdout.print("\n=== 1. 基本指针操作 ===\n", .{});
    try stdout.print("原始值: {d}\n", .{number});
    try stdout.print("通过指针访问: {d}\n", .{ptr.*});

    // 修改指针指向的值
    ptr.* = 100;
    try stdout.print("修改后的值: {d}\n", .{number});

    // 可选指针
    const optional_ptr: ?*i32 = &number;
    if (optional_ptr) |p| {
        try stdout.print("可选指针的值: {d}\n", .{p.*});
    }
}

// 2. 多级指针
fn multiLevelPointers() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== 2. 多级指针 ===\n", .{});

    var value: i32 = 42;
    var ptr1 = &value;
    const ptr2 = &ptr1;

    try stdout.print("原始值: {d}\n", .{value});
    try stdout.print("一级指针: {d}\n", .{ptr1.*});
    try stdout.print("二级指针: {d}\n", .{ptr2.*.*});

    // 通过二级指针修改值
    ptr2.*.* = 100;
    try stdout.print("修改后的值: {d}\n", .{value});
}

// 3. 内存分配
fn memoryAllocation(allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== 3. 内存分配 ===\n", .{});

    // 分配单个整数
    const number = try allocator.create(i32);
    defer allocator.destroy(number);

    number.* = 42;
    try stdout.print("分配的整数: {d}\n", .{number.*});

    // 分配数组
    const array = try allocator.alloc(i32, 5);
    defer allocator.free(array);

    for (array, 0..) |*item, i| {
        item.* = @intCast(i * 10);
    }

    try stdout.print("分配的数组: ", .{});
    for (array) |item| {
        try stdout.print("{d} ", .{item});
    }
    try stdout.print("\n", .{});
}

// 4. 切片操作
fn sliceOperations() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== 4. 切片操作 ===\n", .{});

    // 创建数组和切片
    var array = [_]i32{ 1, 2, 3, 4, 5 };
    const slice = array[1..4];

    try stdout.print("原始数组: ", .{});
    for (array) |item| {
        try stdout.print("{d} ", .{item});
    }
    try stdout.print("\n", .{});

    try stdout.print("切片内容: ", .{});
    for (slice) |item| {
        try stdout.print("{d} ", .{item});
    }
    try stdout.print("\n", .{});

    // 修改切片会影响原数组
    for (slice) |*item| {
        item.* *= 10;
    }

    try stdout.print("修改后的数组: ", .{});
    for (array) |item| {
        try stdout.print("{d} ", .{item});
    }
    try stdout.print("\n", .{});
}

// 5. 指针运算和安全性
fn pointerSafety(allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== 5. 指针安全性 ===\n", .{});

    // 安全的内存访问
    const array = try allocator.alloc(i32, 5);
    defer allocator.free(array);

    for (array, 0..) |*item, i| {
        item.* = @intCast(i + 1);
    }

    // 使用切片进行边界检查
    const slice = array[0..3];
    try stdout.print("安全的切片访问: ", .{});
    for (slice) |item| {
        try stdout.print("{d} ", .{item});
    }
    try stdout.print("\n", .{});

    // 编译时边界检查
    comptime {
        var test_array = [_]i32{ 1, 2, 3 };
        _ = &test_array[0]; // 仅作为示例，展示编译时边界检查
        // const invalid = &test_array[5]; // 这行会导致编译错误
    }
}

// 6. 内存对齐
fn memoryAlignment() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== 6. 内存对齐 ===\n", .{});

    const Aligned = struct {
        a: u8,
        b: u32,
        c: u8,
        d: u16,
    };

    const Packed = packed struct {
        a: u8,
        b: u32,
        c: u8,
        d: u16,
    };

    try stdout.print("普通结构体大小: {d}\n", .{@sizeOf(Aligned)});
    try stdout.print("压缩结构体大小: {d}\n", .{@sizeOf(Packed)});
    try stdout.print("u32 对齐要求: {d}\n", .{@alignOf(u32)});

    try stdout.print("a 的对齐要求: {d}\n", .{@alignOf(u8)});
    try stdout.print("b 的对齐要求: {d}\n", .{@alignOf(u32)});
    try stdout.print("整个结构体的对齐要求: {d}\n", .{@alignOf(Aligned)});
    try stdout.print("结构体内存布局:\n", .{});
    try stdout.print("a 的偏移量: {d}\n", .{@offsetOf(Aligned, "a")});
    try stdout.print("b 的偏移量: {d}\n", .{@offsetOf(Aligned, "b")});
    try stdout.print("c 的偏移量: {d}\n", .{@offsetOf(Aligned, "c")});
}

// 7. 内存泄漏检测
fn memoryLeakDetection(allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== 7. 内存泄漏检测 ===\n", .{});

    // 正确的内存管理
    {
        const data = try allocator.alloc(u8, 100);
        defer allocator.free(data);
        try stdout.print("分配了 100 字节\n", .{});
    }
    try stdout.print("内存已正确释放\n", .{});

    // 演示内存泄漏检测
    // 注释掉以下代码以避免实际的内存泄漏
    // {
    //     const leak = try allocator.alloc(u8, 100);
    //     // 没有使用 defer free，会导致内存泄漏
    // }
}

const ServerConfig = struct {
    host: []const u8 = "localhost",
    port: u16 = 8080,
    max_connections: u32 = 1000,

    pub fn init() ServerConfig {
        return .{};
    }

    pub fn setHost(self: *ServerConfig, host: []const u8) *ServerConfig {
        self.host = host;
        return self;
    }

    pub fn setPort(self: *ServerConfig, port: u16) *ServerConfig {
        self.port = port;
        return self;
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== Zig 内存管理示例 ===\n", .{});

    // 创建分配器
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            @panic("内存泄漏检测到！");
        }
    }
    const allocator = gpa.allocator();

    // 运行所有示例
    try pointerBasics();
    try multiLevelPointers();
    try memoryAllocation(allocator);
    try sliceOperations();
    try pointerSafety(allocator);
    try memoryAlignment();
    try memoryLeakDetection(allocator);

    try stdout.print("\n=== 示例结束 ===\n", .{});

    // 创建服务器配置
    const config = ServerConfig{
        .host = "127.0.0.1",
        .port = 3000,
        .max_connections = 5000,
    };

    try stdout.print("创建的服务器配置: {}\n", .{config});
}

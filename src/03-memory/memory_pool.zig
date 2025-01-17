const std = @import("std");

/// 内存块结构
const MemoryBlock = struct {
    data: []u8, // 实际数据
    size: usize, // 块大小
    is_free: bool, // 是否空闲
    next: ?*MemoryBlock, // 下一个块

    // 创建新的内存块
    pub fn init(data: []u8, size: usize) MemoryBlock {
        return MemoryBlock{
            .data = data,
            .size = size,
            .is_free = true,
            .next = null,
        };
    }
};

/// 内存池错误
const MemoryPoolError = error{
    OutOfMemory,
    InvalidSize,
    InvalidAlignment,
    PoolFull,
};

/// 内存池管理器
pub const MemoryPool = struct {
    allocator: std.mem.Allocator, // 底层分配器
    total_size: usize, // 总大小
    min_block_size: usize, // 最小块大小
    head: ?*MemoryBlock, // 第一个块
    memory: []u8, // 整个内存区域

    /// 创建新的内存池
    pub fn init(allocator: std.mem.Allocator, total_size: usize, min_block_size: usize) !MemoryPool {
        if (total_size < min_block_size) {
            return MemoryPoolError.InvalidSize;
        }

        // 分配内存
        const memory = try allocator.alloc(u8, total_size);
        errdefer allocator.free(memory);

        // 创建初始块
        const initial_block = try allocator.create(MemoryBlock);
        errdefer allocator.destroy(initial_block);

        initial_block.* = MemoryBlock.init(memory, total_size);

        return MemoryPool{
            .allocator = allocator,
            .total_size = total_size,
            .min_block_size = min_block_size,
            .head = initial_block,
            .memory = memory,
        };
    }

    /// 清理内存池
    pub fn deinit(self: *MemoryPool) void {
        // 释放所有内存块
        var current = self.head;
        while (current) |block| {
            const next = block.next;
            self.allocator.destroy(block);
            current = next;
        }

        // 释放内存区域
        self.allocator.free(self.memory);
    }

    /// 分配指定大小的内存
    pub fn alloc(self: *MemoryPool, size: usize) ![]u8 {
        if (size == 0 or size > self.total_size) {
            return MemoryPoolError.InvalidSize;
        }

        // 查找合适的空闲块
        var current = self.head;
        while (current) |block| {
            if (block.is_free and block.size >= size) {
                // 如果块足够大，可能需要分割
                if (block.size >= size + self.min_block_size) {
                    try self.splitBlock(block, size);
                }
                block.is_free = false;
                return block.data[0..size];
            }
            current = block.next;
        }

        return MemoryPoolError.PoolFull;
    }

    /// 释放内存
    pub fn free(self: *MemoryPool, memory: []u8) void {
        var current = self.head;
        while (current) |block| {
            if (block.data.ptr == memory.ptr and block.size >= memory.len) {
                block.is_free = true;
                // 尝试合并相邻的空闲块
                self.mergeBlocks();
                return;
            }
            current = block.next;
        }
    }

    /// 分割内存块
    fn splitBlock(self: *MemoryPool, block: *MemoryBlock, size: usize) !void {
        const remaining_size = block.size - size;

        // 创建新块
        var new_block = try self.allocator.create(MemoryBlock);
        errdefer self.allocator.destroy(new_block);

        // 设置新块
        new_block.* = MemoryBlock.init(block.data[size..], remaining_size);
        new_block.next = block.next;

        // 更新原块
        block.size = size;
        block.next = new_block;
    }

    /// 合并相邻的空闲块
    fn mergeBlocks(self: *MemoryPool) void {
        var current = self.head;
        while (current) |block| : (current = block.next) {
            // 只处理空闲块
            if (!block.is_free) continue;

            // 尝试与下一个块合并
            while (block.next) |next| {
                // 如果下一个块也是空闲的
                if (!next.is_free) break;

                // 合并块
                block.size += next.size;
                block.next = next.next;

                // 释放被合并的块的内存
                self.allocator.destroy(next);
            }
        }
    }

    /// 获取内存池状态
    pub fn getStats(self: *const MemoryPool) struct {
        total_blocks: usize,
        free_blocks: usize,
        largest_free_block: usize,
        fragmentation: f32,
    } {
        var total_blocks: usize = 0;
        var free_blocks: usize = 0;
        var largest_free_block: usize = 0;
        var total_free_size: usize = 0;

        var current = self.head;
        while (current) |block| {
            total_blocks += 1;
            if (block.is_free) {
                free_blocks += 1;
                total_free_size += block.size;
                if (block.size > largest_free_block) {
                    largest_free_block = block.size;
                }
            }
            current = block.next;
        }

        // 计算碎片化程度（0-1，0表示无碎片，1表示完全碎片化）
        const fragmentation = if (total_free_size > 0)
            @as(f32, @floatFromInt(total_free_size - largest_free_block)) / @as(f32, @floatFromInt(total_free_size))
        else
            0;

        return .{
            .total_blocks = total_blocks,
            .free_blocks = free_blocks,
            .largest_free_block = largest_free_block,
            .fragmentation = fragmentation,
        };
    }
};

// 测试
test "MemoryPool basic functionality" {
    const allocator = std.testing.allocator;
    const total_size = 1024;
    const min_block_size = 64;

    // 创建内存池
    var pool = try MemoryPool.init(allocator, total_size, min_block_size);
    defer pool.deinit();

    // 1. 测试初始状态
    {
        const stats = pool.getStats();
        try std.testing.expectEqual(@as(usize, 1), stats.total_blocks);
        try std.testing.expectEqual(@as(usize, 1), stats.free_blocks);
        try std.testing.expectEqual(@as(usize, total_size), stats.largest_free_block);
        try std.testing.expectEqual(@as(f32, 0), stats.fragmentation);
    }

    // 2. 测试内存分配
    var block1: []u8 = undefined;
    var block2: []u8 = undefined;
    {
        block1 = try pool.alloc(128);
        try std.testing.expectEqual(@as(usize, 128), block1.len);

        block2 = try pool.alloc(256);
        try std.testing.expectEqual(@as(usize, 256), block2.len);

        const stats = pool.getStats();
        try std.testing.expectEqual(@as(usize, 3), stats.total_blocks);
        try std.testing.expectEqual(@as(usize, 1), stats.free_blocks);
    }

    // 3. 测试内存释放和合并
    {
        const stats_before = pool.getStats();
        try std.testing.expectEqual(@as(usize, 3), stats_before.total_blocks);
        try std.testing.expectEqual(@as(usize, 1), stats_before.free_blocks);

        // 释放内存块
        pool.free(block1);
        const stats_after_first = pool.getStats();
        try std.testing.expectEqual(@as(usize, 3), stats_after_first.total_blocks);
        try std.testing.expectEqual(@as(usize, 2), stats_after_first.free_blocks);

        pool.free(block2);
        const stats_after = pool.getStats();

        // 验证总块数保持不变
        try std.testing.expectEqual(@as(usize, 3), stats_after.total_blocks);

        // 验证空闲块数量增加到3（初始块和两个新释放的块）
        try std.testing.expectEqual(@as(usize, 3), stats_after.free_blocks);
    }

    // 4. 测试错误处理
    {
        // 尝试分配过大的内存
        try std.testing.expectError(MemoryPoolError.InvalidSize, pool.alloc(total_size + 1));

        // 尝试分配大小为0的内存
        try std.testing.expectError(MemoryPoolError.InvalidSize, pool.alloc(0));
    }
}

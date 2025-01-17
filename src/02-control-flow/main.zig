const std = @import("std");

// 编译时函数
fn comptime_factorial(comptime n: u32) u32 {
    if (n == 0) return 1;
    return n * comptime_factorial(n - 1);
}

// 辅助函数：除法
fn divideNumbers(a: i32, b: i32) !i32 {
    if (b == 0) {
        return error.DivisionByZero;
    }
    return @divTrunc(a, b);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== 控制流示例 ===\n", .{});

    // 1. if-else 示例
    try stdout.print("\n--- If-Else 示例 ---\n", .{});
    const number = 42;
    if (number < 0) {
        try stdout.print("数字是负数\n", .{});
    } else if (number == 0) {
        try stdout.print("数字是零\n", .{});
    } else {
        try stdout.print("数字是正数\n", .{});
    }

    // 2. switch 示例
    try stdout.print("\n--- Switch 示例 ---\n", .{});
    const day = 3;
    const day_name = switch (day) {
        1 => "星期一",
        2 => "星期二",
        3 => "星期三",
        4 => "星期四",
        5 => "星期五",
        6 => "星期六",
        7 => "星期日",
        else => "无效日期",
    };
    try stdout.print("今天是{s}\n", .{day_name});

    // 3. while 循环示例
    try stdout.print("\n--- While 循环示例 ---\n", .{});
    var i: usize = 0;
    while (i < 5) : (i += 1) {
        try stdout.print("{d} ", .{i});
    }
    try stdout.print("\n", .{});

    // 4. for 循环示例
    try stdout.print("\n--- For 循环示例 ---\n", .{});
    const numbers = [_]i32{ 1, 2, 3, 4, 5 };
    for (numbers, 0..) |num, index| {
        try stdout.print("numbers[{d}] = {d}\n", .{ index, num });
    }

    // 5. break 和 continue 示例
    try stdout.print("\n--- Break 和 Continue 示例 ---\n", .{});
    var sum: i32 = 0;
    var num: i32 = 0;
    while (num < 10) : (num += 1) {
        if (num == 5) continue;
        if (num == 8) break;
        sum += num;
    }
    try stdout.print("Sum (跳过5，到8停止): {d}\n", .{sum});

    // 6. 条件循环
    try stdout.print("\n--- 条件循环示例 ---\n", .{});
    var count: i32 = 5;
    while (count > 0) : (count -= 1) {
        try stdout.print("倒计时: {d}\n", .{count});
    }

    // 7. 复杂 switch 示例
    try stdout.print("\n--- 复杂 Switch 示例 ---\n", .{});
    const value: i32 = 42;
    const description = switch (value) {
        0 => "零",
        1...10 => "个位数",
        11...99 => "两位数",
        100...999 => "三位数",
        else => "大数",
    };
    try stdout.print("数字 {d} 是{s}\n", .{ value, description });

    // 8. 多重条件
    try stdout.print("\n--- 多重条件示例 ---\n", .{});
    const a = 5;
    const b = 10;
    if (a > 0 and b > 0) {
        try stdout.print("a 和 b 都是正数\n", .{});
    }
    if (a < 10 or b < 10) {
        try stdout.print("a 或 b 小于10\n", .{});
    }

    // 9. 循环嵌套
    try stdout.print("\n--- 循环嵌套示例 ---\n", .{});
    const size: usize = 3;
    var row: usize = 0;
    while (row < size) : (row += 1) {
        var col: usize = 0;
        while (col < size) : (col += 1) {
            if (row == col) {
                try stdout.print("* ", .{});
            } else {
                try stdout.print(". ", .{});
            }
        }
        try stdout.print("\n", .{});
    }

    // 10. 错误处理流程
    try stdout.print("\n--- 错误处理流程 ---\n", .{});
    const test_numbers = [_]i32{ 10, 0, 5, 0, 2 };
    for (test_numbers, 0..) |n, index| {
        const result = divideNumbers(20, n) catch |err| {
            try stdout.print("第{d}次除法出错: {s}\n", .{ index + 1, @errorName(err) });
            continue;
        };
        try stdout.print("20 ÷ {d} = {d}\n", .{ n, result });
    }

    // 11. 编译时控制流
    try stdout.print("\n--- 编译时控制流 ---\n", .{});
    const fact5 = comptime comptime_factorial(5);
    try stdout.print("编译时计算 5! = {d}\n", .{fact5});

    // 编译时条件编译
    const is_debug = @import("builtin").mode == .Debug;
    if (is_debug) {
        try stdout.print("调试模式已启用\n", .{});
    }

    // 12. 标签和循环控制
    try stdout.print("\n--- 标签和循环控制 ---\n", .{});
    outer: for (0..3) |outer_i| {
        for (0..3) |inner_j| {
            if (outer_i * inner_j > 3) break :outer;
            try stdout.print("({d},{d}) ", .{ outer_i, inner_j });
        }
        try stdout.print("\n", .{});
    }

    // 13. Switch 表达式的高级用法
    try stdout.print("\n--- Switch 高级用法 ---\n", .{});
    const Category = enum { zero, small, medium, large, huge };
    const input = @as(u32, 42);
    const category = switch (input) {
        0 => Category.zero,
        1...10 => Category.small,
        11...100 => Category.medium,
        101...1000 => Category.large,
        else => Category.huge,
    };
    try stdout.print("数字 {d} 的类别是: {s}\n", .{ input, @tagName(category) });
}

const std = @import("std");

// 1. 自定义错误类型
const FileError = error{
    NotFound,
    PermissionDenied,
    InvalidFormat,
};

// 2. 可能返回错误的函数
fn readConfig(path: []const u8) FileError![]const u8 {
    if (path.len == 0) return FileError.NotFound;
    if (std.mem.eql(u8, path, "/root")) return FileError.PermissionDenied;
    if (!std.mem.endsWith(u8, path, ".conf")) return FileError.InvalidFormat;
    return "配置内容";
}

// 3. 错误联合类型
const MathError = error{
    DivisionByZero,
    Overflow,
};

fn divide(a: i32, b: i32) MathError!i32 {
    if (b == 0) return MathError.DivisionByZero;
    if (a == std.math.minInt(i32) and b == -1) return MathError.Overflow;
    return @divTrunc(a, b);
}

// 4. 错误集合合并
const AppError = FileError || MathError;

fn processConfig(path: []const u8, factor: i32) AppError!i32 {
    const content = try readConfig(path);
    _ = content;
    return try divide(100, factor);
}

// 5. 错误处理模式
fn demonstrateErrorHandling() !void {
    const stdout = std.io.getStdOut().writer();

    // 5.1 catch 基本用法
    const result1 = readConfig("") catch |err| {
        try stdout.print("捕获到错误1: {}\n", .{err});
        return;
    };
    _ = result1;

    // 5.2 catch 带默认值
    const result2 = readConfig("/root") catch "默认配置";
    try stdout.print("结果2: {s}\n", .{result2});

    // 5.3 try 运算符
    const result3 = try readConfig("config.conf");
    try stdout.print("结果3: {s}\n", .{result3});

    // 5.4 switch 错误处理
    const result4 = processConfig("bad.txt", 0) catch |err| switch (err) {
        FileError.NotFound => -1,
        FileError.PermissionDenied => -2,
        FileError.InvalidFormat => -3,
        MathError.DivisionByZero => -4,
        MathError.Overflow => -5,
    };
    try stdout.print("结果4: {d}\n", .{result4});
}

// 6. 测试函数
test "基本数学运算测试" {
    try std.testing.expectEqual(@as(i32, 50), try divide(100, 2));
}

test "除零错误测试" {
    try std.testing.expectError(MathError.DivisionByZero, divide(100, 0));
}

test "配置读取测试" {
    try std.testing.expectError(FileError.NotFound, readConfig(""));
    try std.testing.expectError(FileError.PermissionDenied, readConfig("/root"));
    try std.testing.expectError(FileError.InvalidFormat, readConfig("test.txt"));
    try std.testing.expectEqualStrings("配置内容", try readConfig("test.conf"));
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== Zig 错误处理演示 ===\n\n", .{});

    try demonstrateErrorHandling();

    try stdout.print("\n=== 错误处理演示结束 ===\n", .{});
}

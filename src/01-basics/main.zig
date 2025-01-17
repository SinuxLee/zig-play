const std = @import("std");

const Account = struct {
    number: i32,
    balance: f64,
    owner: []const u8,

    const Self = @This();
    pub const AccountError = error{
        InsufficientFunds,
        InvalidAmount,
    };

    pub fn new(id: i32, name: []const u8) Self {
        return Self{
            .number = id,
            .balance = 0.0,
            .owner = name,
        };
    }

    pub fn deposit(self: *Self, amount: f64) AccountError!f64 {
        if (amount <= 0) {
            return AccountError.InvalidAmount;
        }
        self.balance += amount;
        return self.balance;
    }

    pub fn withdraw(self: *Self, amount: f64) AccountError!f64 {
        if (amount <= 0) {
            return AccountError.InvalidAmount;
        }
        if (amount > self.balance) {
            return AccountError.InsufficientFunds;
        }
        self.balance -= amount;
        return self.balance;
    }

    pub fn getBalance(self: Self) f64 {
        return self.balance;
    }

    pub fn print(self: Self) void {
        std.debug.print("账户号: {d}, 余额: {d:.2}, 户主: {s}\n", .{ self.number, self.balance, self.owner });
    }
};

pub fn find(comptime T: type, array: []const T, value: T) ?usize {
    for (array, 0..) |item, index| {
        if (item == value) {
            return index;
        }
    }
    return null;
}

pub fn sum(comptime T: type, array: []const T) T {
    var total: T = 0;
    for (array) |item| {
        total += item;
    }
    return total;
}

pub fn filter(comptime T: type, allocator: std.mem.Allocator, array: []const T, predicate: fn (T) bool) ![]T {
    // 首先计算结果数组的大小
    var count: usize = 0;
    for (array) |item| {
        if (predicate(item)) {
            count += 1;
        }
    }

    // 分配内存
    var result = try allocator.alloc(T, count);
    errdefer allocator.free(result); // 错误发生时释放内存

    // 填充结果数组
    var index: usize = 0;
    for (array) |item| {
        if (predicate(item)) {
            result[index] = item;
            index += 1;
        }
    }

    return result;
}

// 定义一个结构体
const Person = struct {
    name: []const u8,
    age: u32,

    pub fn greet(self: Person) void {
        std.debug.print("你好，我是{s}，今年{d}岁\n", .{ self.name, self.age });
    }
};

// 定义一个枚举
const Color = enum {
    red,
    green,
    blue,

    pub fn toString(self: Color) []const u8 {
        return switch (self) {
            .red => "红色",
            .green => "绿色",
            .blue => "蓝色",
        };
    }
};

// 定义一个联合类型
const Value = union(enum) {
    int: i32,
    float: f32,
    text: []const u8,

    pub fn print(self: Value) void {
        switch (self) {
            .int => |v| std.debug.print("整数: {d}\n", .{v}),
            .float => |v| std.debug.print("浮点数: {d:.2}\n", .{v}),
            .text => |v| std.debug.print("文本: {s}\n", .{v}),
        }
    }
};

// 编译时函数
fn fibonacci(comptime n: u32) u32 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

// 泛型函数
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

fn reverse(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var result = try allocator.alloc(u8, s.len);
    for (s, 0..) |char, i| {
        result[s.len - i - 1] = char;
    }
    return result;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // 1. 基本类型和变量
    try stdout.print("\n=== 基本类型和变量 ===\n", .{});
    const constant_value = 42;
    var mutable_value: i32 = 100;
    try stdout.print("常量值: {d}\n", .{constant_value});
    try stdout.print("初始可变值: {d}\n", .{mutable_value});
    mutable_value += 50;
    try stdout.print("修改后的可变值: {d}\n", .{mutable_value});

    // 2. 字符串操作
    try stdout.print("\n=== 字符串操作 ===\n", .{});
    const name: []const u8 = "Zig语言";
    const greeting = "你好, ";
    try stdout.print("{s}{s}!\n", .{ greeting, name });
    try stdout.print("字符串长度: {d}\n", .{name.len});

    // 3. 数组和切片
    try stdout.print("\n=== 数组和切片 ===\n", .{});
    const numbers = [_]i32{ 1, 2, 3, 4, 5 };
    const slice = numbers[1..4];
    try stdout.print("完整数组: ", .{});
    for (numbers) |num| {
        try stdout.print("{d} ", .{num});
    }
    try stdout.print("\n切片: ", .{});
    for (slice) |num| {
        try stdout.print("{d} ", .{num});
    }
    try stdout.print("\n", .{});

    // 4. 数学运算
    try stdout.print("\n=== 数学运算 ===\n", .{});
    const a: i32 = 10;
    const b: i32 = 3;
    try stdout.print("加法: {d} + {d} = {d}\n", .{ a, b, a + b });
    try stdout.print("减法: {d} - {d} = {d}\n", .{ a, b, a - b });
    try stdout.print("乘法: {d} * {d} = {d}\n", .{ a, b, a * b });
    try stdout.print("除法: {d} / {d} = {d}\n", .{ a, b, @divTrunc(a, b) });
    try stdout.print("取余: {d} % {d} = {d}\n", .{ a, b, @mod(a, b) });

    // 5. 类型转换
    try stdout.print("\n=== 类型转换 ===\n", .{});
    const float_num: f32 = 3.14;
    const int_num = @as(i32, @intFromFloat(float_num));
    try stdout.print("浮点数: {d:.2}\n", .{float_num});
    try stdout.print("转换为整数: {d}\n", .{int_num});

    // 6. 可选类型
    try stdout.print("\n=== 可选类型 ===\n", .{});
    var optional_value: ?i32 = 42;
    try stdout.print("可选值（有值）: ", .{});
    if (optional_value) |value| {
        try stdout.print("{d}\n", .{value});
    }

    optional_value = null;
    try stdout.print("可选值（空值）: ", .{});
    if (optional_value) |value| {
        try stdout.print("{d}\n", .{value});
    } else {
        try stdout.print("null\n", .{});
    }

    // 7. 错误处理示例
    try stdout.print("\n=== 错误处理 ===\n", .{});
    const result = divide(10, 2);
    if (result) |value| {
        try stdout.print("10 / 2 = {d}\n", .{value});
    } else |err| {
        try stdout.print("错误: {}\n", .{err});
    }

    const error_result = divide(10, 0);
    if (error_result) |value| {
        try stdout.print("10 / 0 = {d}\n", .{value});
    } else |err| {
        try stdout.print("错误: {}\n", .{err});
    }

    // 8. 字符串反转示例
    const test_str = "Hello, Zig!";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const reversed = try reverse(allocator, test_str);
    defer allocator.free(reversed);

    try stdout.print("\n=== 字符串反转 ===\n", .{});
    try stdout.print("原始字符串: {s}\n", .{test_str});
    try stdout.print("反转后: {s}\n", .{reversed});

    for (1..10) |i| {
        for (1..i + 1) |j| {
            try stdout.print("{d}*{d}={d}\t", .{ j, i, j * i });
        }
        try stdout.print("\n", .{});
    }

    // 9. 复合类型示例
    try stdout.print("\n=== 复合类型 ===\n", .{});

    // 结构体示例
    const person = Person{ .name = "张三", .age = 25 };
    person.greet();

    // 枚举示例
    const color = Color.red;
    try stdout.print("颜色: {s}\n", .{color.toString()});

    // 联合类型示例
    var value = Value{ .int = 42 };
    value.print();
    value = Value{ .text = "Hello" };
    value.print();

    // 10. 位运算示例
    try stdout.print("\n=== 位运算 ===\n", .{});
    const x: u8 = 0b1010;
    const y: u8 = 0b1100;
    try stdout.print("x = {b:0>8}\n", .{x});
    try stdout.print("y = {b:0>8}\n", .{y});
    try stdout.print("x & y = {b:0>8}\n", .{x & y});
    try stdout.print("x | y = {b:0>8}\n", .{x | y});
    try stdout.print("x ^ y = {b:0>8}\n", .{x ^ y});
    try stdout.print("x << 2 = {b:0>8}\n", .{x << 2});
    try stdout.print("x >> 1 = {b:0>8}\n", .{x >> 1});

    // 11. 编译时计算示例
    try stdout.print("\n=== 编译时计算 ===\n", .{});
    const fib_10 = comptime fibonacci(10);
    try stdout.print("第10个斐波那契数: {d}\n", .{fib_10});

    // 12. 泛型示例
    try stdout.print("\n=== 泛型函数 ===\n", .{});
    try stdout.print("max(i32, 10, 20) = {d}\n", .{max(i32, 10, 20)});
    try stdout.print("max(f32, 3.14, 2.718) = {d:.3}\n", .{max(f32, 3.14, 2.718)});

    const accounts = try allocator.alloc(Account, 2);
    defer allocator.free(accounts);

    var acc = Account.new(1, "张三");
    accounts[0] = acc;
    _ = try acc.deposit(100);
    acc.print();
    _ = try acc.withdraw(50);
    acc.print();
}

// 自定义错误类型
const DivisionError = error{
    DivisionByZero,
};

// 返回错误联合类型的函数
fn divide(a: i32, b: i32) DivisionError!i32 {
    if (b == 0) {
        return DivisionError.DivisionByZero;
    }
    return @divTrunc(a, b);
}

// 添加测试函数
test "Account operations" {
    // 测试账户基本操作
    var account = Account.new(1001, "测试账户");
    try std.testing.expectEqual(account.getBalance(), 0.0);

    // 测试存款
    _ = try account.deposit(100.0);
    try std.testing.expectEqual(account.getBalance(), 100.0);

    // 测试取款
    _ = try account.withdraw(30.0);
    try std.testing.expectEqual(account.getBalance(), 70.0);

    // 测试错误情况
    try std.testing.expectError(Account.AccountError.InsufficientFunds, account.withdraw(100.0));
    try std.testing.expectError(Account.AccountError.InvalidAmount, account.deposit(-50.0));
    try std.testing.expectError(Account.AccountError.InvalidAmount, account.withdraw(-20.0));
}

test "Array operations" {
    const allocator = std.testing.allocator;

    // 测试查找函数
    const numbers = [_]i32{ 1, 3, 5, 7, 9 };
    try std.testing.expectEqual(find(i32, &numbers, 5), 2);
    try std.testing.expectEqual(find(i32, &numbers, 4), null);

    // 测试求和函数
    try std.testing.expectEqual(sum(i32, &numbers), 25);

    // 测试过滤函数
    const isEven = struct {
        fn predicate(n: i32) bool {
            return @mod(n, 2) == 0;
        }
    }.predicate;

    const array = [_]i32{ 1, 2, 3, 4, 5, 6 };
    const filtered = try filter(i32, allocator, &array, isEven);
    defer allocator.free(filtered);

    try std.testing.expectEqual(filtered.len, 3);
    try std.testing.expectEqual(filtered[0], 2);
    try std.testing.expectEqual(filtered[1], 4);
    try std.testing.expectEqual(filtered[2], 6);
}

test "String operations" {
    const allocator = std.testing.allocator;

    // 测试字符串反转
    const original = "Hello, 世界!";
    const reversed = try reverse(allocator, original);
    defer allocator.free(reversed);

    // 注意：这里我们需要手动创建预期的结果，因为字符串字面量是UTF-8编码的
    const expected = "!界世 ,olleH";
    try std.testing.expectEqualStrings(reversed, expected);
}

test "Compile time operations" {
    // 测试编译时斐波那契数列
    try std.testing.expectEqual(comptime fibonacci(0), 0);
    try std.testing.expectEqual(comptime fibonacci(1), 1);
    try std.testing.expectEqual(comptime fibonacci(5), 5);
    try std.testing.expectEqual(comptime fibonacci(10), 55);

    // 测试泛型最大值函数
    try std.testing.expectEqual(max(i32, 10, 20), 20);
    try std.testing.expectEqual(max(i32, -5, -10), -5);
    try std.testing.expectEqual(max(f32, 3.14, 2.718), 3.14);
}

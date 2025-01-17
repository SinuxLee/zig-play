const std = @import("std");

// 1. 编译期函数：计算阶乘
fn comptime_factorial(comptime n: u32) u32 {
    if (n == 0) return 1;
    return n * comptime_factorial(n - 1);
}

// 2. 泛型函数：交换两个值
fn swap(comptime T: type, a: *T, b: *T) void {
    const temp = a.*;
    a.* = b.*;
    b.* = temp;
}

// 3. 编译期类型推导和反射
fn printTypeInfo(comptime T: type) void {
    const info = @typeInfo(T);
    switch (info) {
        .Int => |int_info| {
            std.debug.print("整数类型: 有符号={}, 位数={}\n", .{
                int_info.signedness == .signed,
                int_info.bits,
            });
        },
        .Struct => |struct_info| {
            std.debug.print("结构体类型: 字段数={}\n", .{struct_info.fields.len});
        },
        else => std.debug.print("未知类型\n", .{}),
    }
}

// 4. 元编程：根据条件生成代码
fn generateValidator(comptime T: type) type {
    return struct {
        pub fn validate(value: T) bool {
            return switch (@typeInfo(T)) {
                .Int => value >= 0,
                .Float => !std.math.isNan(value),
                else => true,
            };
        }
    };
}

// 5. 高级类型系统：类型安全的联合类型
const Result = union(enum) {
    success: []const u8,
    err: anyerror,

    pub fn isSuccess(self: @This()) bool {
        return self == .success;
    }
};

// 6. 编译期类型转换和约束
fn convertAndValidate(comptime From: type, comptime To: type, value: From) !To {
    // 编译期检查类型兼容性
    comptime {
        if (!@hasDecl(@TypeOf(value), "value")) {
            @compileError("不支持的转换");
        }
    }

    // 运行时转换
    return @as(To, @intCast(value));
}

// 7. 高级枚举特性
const Color = enum {
    red,
    green,
    blue,

    pub fn isRGB(self: @This()) bool {
        return self != .red;
    }

    pub fn toHex(self: @This()) []const u8 {
        return switch (self) {
            .red => "#FF0000",
            .green => "#00FF00",
            .blue => "#0000FF",
        };
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n=== Zig 高级特性 ===\n", .{});

    // 1. 编译期阶乘计算
    const fact5 = comptime_factorial(5);
    try stdout.print("编译期阶乘(5!): {d}\n", .{fact5});

    // 2. 泛型交换
    var a: i32 = 10;
    var b: i32 = 20;
    swap(i32, &a, &b);
    try stdout.print("交换后: a={d}, b={d}\n", .{ a, b });

    // 3. 类型信息打印
    printTypeInfo(i32);
    printTypeInfo(struct { x: f32, y: f32 });

    // 4. 类型验证器
    const IntValidator = generateValidator(i32);
    const FloatValidator = generateValidator(f32);
    try stdout.print("整数验证: {}\n", .{IntValidator.validate(42)});
    try stdout.print("浮点数验证: {}\n", .{FloatValidator.validate(3.14)});

    // 5. 类型安全的联合类型
    const success_result = Result{ .success = "操作成功" };
    const error_result = Result{ .err = error.InvalidArgument };
    try stdout.print("成功结果: {}\n", .{success_result.isSuccess()});
    try stdout.print("错误结果: {}\n", .{error_result.isSuccess()});

    // 6. 颜色枚举
    const color = Color.green;
    try stdout.print("颜色: {s}, 是否RGB: {}, 十六进制: {s}\n", .{
        @tagName(color),
        color.isRGB(),
        color.toHex(),
    });

    try stdout.print("\n=== 高级特性演示结束 ===\n", .{});
}

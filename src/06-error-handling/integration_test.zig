const std = @import("std");
const ConfigManager = @import("config_manager.zig").ConfigManager;
const ConfigError = @import("config_manager.zig").ConfigError;

test "配置管理器集成测试 - 基本操作" {
    // 设置
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_file = "test_config.conf";
    defer std.fs.cwd().deleteFile(test_file) catch {};

    // 1. 创建和写入配置
    {
        var manager = ConfigManager.init(allocator, test_file);
        defer manager.deinit();

        try manager.setValue("database.host", "localhost");
        try manager.setValue("database.port", "5432");
        try manager.setValue("app.name", "测试应用");

        try manager.save();
    }

    // 2. 读取和验证配置
    {
        var manager = ConfigManager.init(allocator, test_file);
        defer manager.deinit();

        try manager.load();

        try std.testing.expectEqualStrings(
            "localhost",
            manager.getValue("database.host") orelse return error.TestUnexpectedNull,
        );
        try std.testing.expectEqualStrings(
            "5432",
            manager.getValue("database.port") orelse return error.TestUnexpectedNull,
        );
        try std.testing.expectEqualStrings(
            "测试应用",
            manager.getValue("app.name") orelse return error.TestUnexpectedNull,
        );
    }
}

test "配置管理器集成测试 - 错误处理" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // 1. 测试不存在的文件
    {
        var manager = ConfigManager.init(allocator, "nonexistent.conf");
        defer manager.deinit();

        try std.testing.expectError(ConfigError.InvalidPath, manager.load());
    }

    // 2. 测试无效的配置文件
    {
        const invalid_file = "invalid.conf";
        defer std.fs.cwd().deleteFile(invalid_file) catch {};

        const file = try std.fs.cwd().createFile(invalid_file, .{});
        try file.writeAll("invalid=config=format\n");
        file.close();

        var manager = ConfigManager.init(allocator, invalid_file);
        defer manager.deinit();

        try std.testing.expectError(ConfigError.ParseError, manager.load());
    }

    // 3. 测试写入权限
    {
        const readonly_file = "readonly.conf";
        defer std.fs.cwd().deleteFile(readonly_file) catch {};

        const file = try std.fs.cwd().createFile(readonly_file, .{});
        try file.writeAll("test=value\n");
        file.close();

        // 重新打开文件为只读模式
        const read_only = try std.fs.cwd().openFile(readonly_file, .{ .mode = .read_only });
        read_only.close();

        var manager = ConfigManager.init(allocator, readonly_file);
        defer manager.deinit();

        try manager.setValue("test", "new_value");
        try std.testing.expectError(ConfigError.WriteError, manager.save());
    }
}

test "配置管理器集成测试 - 性能测试" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const perf_file = "perf_test.conf";
    defer std.fs.cwd().deleteFile(perf_file) catch {};

    var manager = ConfigManager.init(allocator, perf_file);
    defer manager.deinit();

    // 写入大量配置项
    const num_entries = 1000;
    var i: usize = 0;
    while (i < num_entries) : (i += 1) {
        const key = try std.fmt.allocPrint(allocator, "key_{d}", .{i});
        defer allocator.free(key);
        const value = try std.fmt.allocPrint(allocator, "value_{d}", .{i});
        defer allocator.free(value);
        try manager.setValue(key, value);
    }

    // 保存配置
    const save_start = std.time.nanoTimestamp();
    try manager.save();
    const save_end = std.time.nanoTimestamp();
    const save_duration = @as(f64, @floatFromInt(save_end - save_start)) / std.time.ns_per_ms;

    // 加载配置
    const load_start = std.time.nanoTimestamp();
    try manager.load();
    const load_end = std.time.nanoTimestamp();
    const load_duration = @as(f64, @floatFromInt(load_end - load_start)) / std.time.ns_per_ms;

    // 验证性能指标
    try std.testing.expect(save_duration < 1000); // 保存时间应小于1秒
    try std.testing.expect(load_duration < 1000); // 加载时间应小于1秒
}

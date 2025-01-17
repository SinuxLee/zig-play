const std = @import("std");

pub const ConfigError = error{
    InvalidPath,
    InvalidContent,
    ParseError,
    WriteError,
    OutOfMemory,
};

pub const Config = struct {
    allocator: std.mem.Allocator,
    data: std.StringHashMap([]const u8),

    pub fn init(allocator: std.mem.Allocator) Config {
        return .{
            .allocator = allocator,
            .data = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *Config) void {
        var iter = self.data.iterator();
        while (iter.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
        self.data.deinit();
    }

    pub fn set(self: *Config, key: []const u8, value: []const u8) !void {
        const key_dup = try self.allocator.dupe(u8, key);
        errdefer self.allocator.free(key_dup);
        const value_dup = try self.allocator.dupe(u8, value);
        errdefer self.allocator.free(value_dup);

        if (self.data.get(key_dup)) |old_value| {
            self.allocator.free(old_value);
        }
        try self.data.put(key_dup, value_dup);
    }

    pub fn get(self: *const Config, key: []const u8) ?[]const u8 {
        return self.data.get(key);
    }
};

pub const ConfigManager = struct {
    config: Config,
    path: []const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, path: []const u8) ConfigManager {
        return .{
            .config = Config.init(allocator),
            .path = path,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ConfigManager) void {
        self.config.deinit();
    }

    pub fn load(self: *ConfigManager) ConfigError!void {
        const file = std.fs.cwd().openFile(self.path, .{}) catch |err| switch (err) {
            error.FileNotFound => return ConfigError.InvalidPath,
            else => return ConfigError.InvalidContent,
        };
        defer file.close();

        const content = file.readToEndAlloc(self.allocator, 1024 * 1024) catch {
            return ConfigError.InvalidContent;
        };
        defer self.allocator.free(content);

        var lines = std.mem.split(u8, content, "\n");
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");
            if (trimmed.len == 0 or trimmed[0] == '#') continue;

            var kv = std.mem.split(u8, trimmed, "=");
            const key = kv.next() orelse return ConfigError.ParseError;
            const value = kv.next() orelse return ConfigError.ParseError;
            if (kv.next() != null) return ConfigError.ParseError;

            try self.config.set(
                std.mem.trim(u8, key, " "),
                std.mem.trim(u8, value, " "),
            );
        }
    }

    pub fn save(self: *const ConfigManager) ConfigError!void {
        const file = std.fs.cwd().createFile(self.path, .{}) catch {
            return ConfigError.WriteError;
        };
        defer file.close();

        const writer = file.writer();
        var iter = self.config.data.iterator();
        while (iter.next()) |entry| {
            writer.print("{s}={s}\n", .{ entry.key_ptr.*, entry.value_ptr.* }) catch {
                return ConfigError.WriteError;
            };
        }
    }

    pub fn setValue(self: *ConfigManager, key: []const u8, value: []const u8) !void {
        try self.config.set(key, value);
    }

    pub fn getValue(self: *const ConfigManager, key: []const u8) ?[]const u8 {
        return self.config.get(key);
    }
};

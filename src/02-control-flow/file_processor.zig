const std = @import("std");

// 自定义错误类型
const FileProcessError = error{
    FileNotFound,
    PermissionDenied,
    OutOfMemory,
    InvalidFormat,
    ProcessingError,
};

// 文件统计信息
const FileStats = struct {
    line_count: usize,
    word_count: usize,
    char_count: usize,
};

// 行迭代器
const LineIterator = struct {
    content: []const u8,
    index: usize,

    pub fn init(content: []const u8) LineIterator {
        return LineIterator{
            .content = content,
            .index = 0,
        };
    }

    // 获取下一行
    pub fn next(self: *LineIterator) ?[]const u8 {
        // 如果已经到达内容末尾，返回null
        if (self.index >= self.content.len) return null;

        // 查找下一个换行符或内容末尾
        var line_end = self.index;
        while (line_end < self.content.len and self.content[line_end] != '\n') {
            line_end += 1;
        }

        // 获取当前行（不包含换行符）
        const line = self.content[self.index..line_end];

        // 更新索引到下一行开始位置
        // 如果找到换行符，跳过它；否则移动到内容末尾
        self.index = if (line_end < self.content.len) line_end + 1 else self.content.len;

        return line;
    }
};

// 文本转换选项
const TextTransform = enum {
    none,
    uppercase,
    lowercase,
    titlecase,
};

// 文件处理器
const FileProcessor = struct {
    allocator: std.mem.Allocator,
    file_path: []const u8,
    cached_content: ?[]const u8, // 缓存的文件内容

    // 构造函数
    pub fn init(allocator: std.mem.Allocator, file_path: []const u8) FileProcessor {
        return FileProcessor{
            .allocator = allocator,
            .file_path = file_path,
            .cached_content = null,
        };
    }

    // 析构函数
    pub fn deinit(self: *FileProcessor) void {
        if (self.cached_content) |content| {
            self.allocator.free(content);
            self.cached_content = null;
        }
    }

    // 读取文件内容（带缓存）
    pub fn readContent(self: *FileProcessor) ![]const u8 {
        // 如果有缓存，直接返回
        if (self.cached_content) |content| {
            return content;
        }

        const file = try std.fs.cwd().openFile(self.file_path, .{});
        defer file.close();

        // 获取文件大小
        const file_size = try file.getEndPos();
        if (file_size > std.math.maxInt(usize)) {
            return FileProcessError.OutOfMemory;
        }

        // 分配内存并读取文件
        const buffer = try self.allocator.alloc(u8, @intCast(file_size));
        errdefer self.allocator.free(buffer);

        const bytes_read = try file.readAll(buffer);
        if (bytes_read != file_size) {
            return FileProcessError.ProcessingError;
        }

        // 保存到缓存并返回
        self.cached_content = buffer;
        return buffer;
    }

    // 清除缓存
    pub fn clearCache(self: *FileProcessor) void {
        if (self.cached_content) |content| {
            self.allocator.free(content);
            self.cached_content = null;
        }
    }

    // 获取行迭代器
    pub fn iterLines(self: *FileProcessor) !LineIterator {
        const content = try self.readContent();
        return LineIterator.init(content);
    }

    // 转换文本内容
    pub fn transformContent(self: *FileProcessor, transform: TextTransform) ![]const u8 {
        const content = try self.readContent();
        var result = try self.allocator.alloc(u8, content.len);
        errdefer self.allocator.free(result);

        switch (transform) {
            .none => {
                @memcpy(result, content);
            },
            .uppercase => {
                for (content, 0..) |char, i| {
                    result[i] = if (std.ascii.isLower(char))
                        std.ascii.toUpper(char)
                    else
                        char;
                }
            },
            .lowercase => {
                for (content, 0..) |char, i| {
                    result[i] = if (std.ascii.isUpper(char))
                        std.ascii.toLower(char)
                    else
                        char;
                }
            },
            .titlecase => {
                var should_capitalize = true;
                for (content, 0..) |char, i| {
                    if (std.ascii.isWhitespace(char) or char == '\n') {
                        should_capitalize = true;
                        result[i] = char;
                    } else if (should_capitalize and std.ascii.isAlphabetic(char)) {
                        result[i] = std.ascii.toUpper(char);
                        should_capitalize = false;
                    } else {
                        result[i] = std.ascii.toLower(char);
                        should_capitalize = false;
                    }
                }
            },
        }

        return result;
    }

    // 通用行过滤函数
    pub fn filterLines(self: *FileProcessor, comptime filterFn: fn (line: []const u8) bool) ![]const u8 {
        const content = try self.readContent();
        var filtered = std.ArrayList(u8).init(self.allocator);
        errdefer filtered.deinit();

        var iter = LineIterator.init(content);
        var is_first_line = true;

        while (iter.next()) |line| {
            // 使用传入的过滤函数判断是否保留该行
            if (!filterFn(line)) continue;

            // 在非第一行前添加换行符
            if (!is_first_line) {
                try filtered.append('\n');
            }
            try filtered.appendSlice(line);
            is_first_line = false;
        }

        return filtered.toOwnedSlice();
    }

    // 过滤空行（使用通用过滤函数实现）
    pub fn filterEmptyLines(self: *FileProcessor) ![]const u8 {
        const filterEmpty = struct {
            fn filter(line: []const u8) bool {
                return line.len > 0;
            }
        }.filter;
        return self.filterLines(filterEmpty);
    }

    // 统计文件信息
    pub fn getStats(self: *FileProcessor) !FileStats {
        const content = try self.readContent();

        var stats = FileStats{
            .line_count = 0,
            .word_count = 0,
            .char_count = content.len,
        };

        var in_word = false;
        for (content) |char| {
            switch (char) {
                '\n' => {
                    stats.line_count += 1;
                    if (in_word) {
                        stats.word_count += 1;
                        in_word = false;
                    }
                },
                ' ', '\t', '\r' => {
                    if (in_word) {
                        stats.word_count += 1;
                        in_word = false;
                    }
                },
                else => {
                    in_word = true;
                },
            }
        }

        // 处理最后一个词
        if (in_word) {
            stats.word_count += 1;
        }

        // 如果文件不是空的且不以换行符结束，增加行数
        if (stats.char_count > 0 and content[content.len - 1] != '\n') {
            stats.line_count += 1;
        }

        return stats;
    }
};

// 测试函数
test "FileProcessor basic functionality" {
    const allocator = std.testing.allocator;

    // 创建测试文件
    const test_content =
        \\Hello World
        \\This is a test file
        \\
        \\With multiple lines
        \\And some words
    ;

    const test_file = "test.txt";
    {
        const file = try std.fs.cwd().createFile(test_file, .{});
        defer file.close();
        try file.writeAll(test_content);
    }
    defer std.fs.cwd().deleteFile(test_file) catch {};

    // 测试文件处理
    var processor = FileProcessor.init(allocator, test_file);

    // 1. 测试基本统计
    const stats = try processor.getStats();
    try std.testing.expectEqual(@as(usize, 5), stats.line_count);
    try std.testing.expectEqual(@as(usize, 13), stats.word_count);
    try std.testing.expect(stats.char_count > 0);

    // 2. 测试行迭代器
    {
        var line_count: usize = 0;
        var iter = try processor.iterLines();
        while (iter.next()) |line| {
            _ = line;
            line_count += 1;
        }
        try std.testing.expectEqual(@as(usize, 5), line_count);
    }

    // 3. 测试文本转换
    {
        // 测试大写转换
        const upper_content = try processor.transformContent(.uppercase);
        defer allocator.free(upper_content);
        for (upper_content) |char| {
            if (std.ascii.isAlphabetic(char)) {
                try std.testing.expect(std.ascii.isUpper(char));
            }
        }

        // 测试标题格式转换
        const title_content = try processor.transformContent(.titlecase);
        defer allocator.free(title_content);
        var iter = LineIterator.init(title_content);
        while (iter.next()) |line| {
            if (line.len > 0) {
                // 检查每行的第一个字母是否为大写
                if (std.ascii.isAlphabetic(line[0])) {
                    try std.testing.expect(std.ascii.isUpper(line[0]));
                }
                // 检查单词之间的首字母是否为大写
                for (line[1..], 0..line.len - 1) |_, i| {
                    if (std.ascii.isWhitespace(line[i]) and i + 1 < line.len) {
                        const next_char = line[i + 1];
                        if (std.ascii.isAlphabetic(next_char)) {
                            try std.testing.expect(std.ascii.isUpper(next_char));
                        }
                    }
                }
            }
        }
    }

    // 4. 测试空行过滤
    {
        const filtered = try processor.filterEmptyLines();
        defer allocator.free(filtered);

        var filtered_line_count: usize = 0;
        var iter = LineIterator.init(filtered);
        while (iter.next()) |line| {
            try std.testing.expect(line.len > 0);
            filtered_line_count += 1;
        }
        try std.testing.expectEqual(@as(usize, 4), filtered_line_count);
    }

    // 5. 测试通用行过滤
    {
        // 定义一个过滤函数：只保留包含 "test" 的行
        const containsTest = struct {
            fn filter(line: []const u8) bool {
                return std.mem.indexOf(u8, line, "test") != null;
            }
        }.filter;

        const filtered = try processor.filterLines(containsTest);
        defer allocator.free(filtered);

        var found_test = false;
        var iter = LineIterator.init(filtered);
        while (iter.next()) |line| {
            if (line.len > 0) {
                try std.testing.expect(std.mem.indexOf(u8, line, "test") != null);
                found_test = true;
            }
        }
        try std.testing.expect(found_test);
    }

    // 6. 测试缓存机制
    {
        // 首次读取，应该从文件读取
        const content1 = try processor.readContent();
        const first_addr = @intFromPtr(content1.ptr);

        // 第二次读取，应该从缓存获取
        const content2 = try processor.readContent();
        const second_addr = @intFromPtr(content2.ptr);

        // 验证两次读取的是同一块内存
        try std.testing.expectEqual(first_addr, second_addr);

        // 清除缓存
        processor.clearCache();

        // 再次读取，应该重新从文件读取
        const content3 = try processor.readContent();
        const third_addr = @intFromPtr(content3.ptr);

        // 验证这是一个新的内存块
        try std.testing.expect(first_addr != third_addr);
    }

    // 清理资源
    processor.deinit();
}

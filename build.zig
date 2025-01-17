const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 基础项目
    const basics = b.addExecutable(.{
        .name = "01-basics",
        .root_source_file = .{ .cwd_relative = "src/01-basics/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(basics);
    const basics_run_cmd = b.addRunArtifact(basics);
    const basics_step = b.step("basics", "Run the basics example");
    basics_step.dependOn(&basics_run_cmd.step);

    // 控制流项目
    const control = b.addExecutable(.{
        .name = "02-control-flow",
        .root_source_file = .{ .cwd_relative = "src/02-control-flow/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(control);
    const control_run_cmd = b.addRunArtifact(control);
    const control_step = b.step("control", "Run the control flow example");
    control_step.dependOn(&control_run_cmd.step);

    // 内存管理项目
    const memory = b.addExecutable(.{
        .name = "03-memory",
        .root_source_file = .{ .cwd_relative = "src/03-memory/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(memory);
    const memory_run_cmd = b.addRunArtifact(memory);
    const memory_step = b.step("memory", "Run the memory management example");
    memory_step.dependOn(&memory_run_cmd.step);

    // 高级特性项目
    const advanced = b.addExecutable(.{
        .name = "04-advanced",
        .root_source_file = .{ .cwd_relative = "src/04-advanced/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(advanced);
    const advanced_run_cmd = b.addRunArtifact(advanced);
    const advanced_step = b.step("advanced", "Run the advanced features example");
    advanced_step.dependOn(&advanced_run_cmd.step);

    // 并发编程项目
    const concurrency = b.addExecutable(.{
        .name = "05-concurrency",
        .root_source_file = .{ .cwd_relative = "src/05-concurrency/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(concurrency);
    const concurrency_run_cmd = b.addRunArtifact(concurrency);
    const concurrency_step = b.step("concurrency", "Run the concurrency example");
    concurrency_step.dependOn(&concurrency_run_cmd.step);

    // 错误处理项目
    const error_handling = b.addExecutable(.{
        .name = "06-error-handling",
        .root_source_file = .{ .cwd_relative = "src/06-error-handling/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(error_handling);
    const error_handling_run_cmd = b.addRunArtifact(error_handling);
    const error_handling_step = b.step("error-handling", "Run the error handling example");
    error_handling_step.dependOn(&error_handling_run_cmd.step);

    // 单元测试
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/06-error-handling/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    // 集成测试
    const integration_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/06-error-handling/integration_test.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_integration_tests = b.addRunArtifact(integration_tests);

    // 测试步骤
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_unit_tests.step);
    test_step.dependOn(&run_integration_tests.step);

    // 单独的集成测试步骤
    const integration_test_step = b.step("test-integration", "Run integration tests");
    integration_test_step.dependOn(&run_integration_tests.step);
}

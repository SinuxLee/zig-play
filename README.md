## Learn Zig Lang
### zig feature
0. [overview](https://ziglang.org/learn/samples/)
1. [cookbook](https://cookbook.ziglang.cc/intro.html)
2. [zigbook](https://pedropark99.github.io/zig-book/)
3. [course](https://course.ziglang.cc/) 圣经
4. [guide](https://zig.guide/)
5. [zig std doc](https://ziglang.org/documentation/master/)
6. [learning zig](https://ziglang.cc/learn/preface/)


### dev tools
1. zls, vscode + config
2. debugger, lldb/cppvsdbg
3. deps, zig fetch
   ```
   # version
   zig fetch --save "git+https://github.com/zigzap/zap#v0.9.1"

   # branch
   zig fetch --save "git+https://github.com/mitchellh/libxev#main"

   # tar
   zig fetch --save https://github.com/tidwall/btree.c/archive/v0.6.1.tar.gz
   ```
4. mix and cross compile, c/c++/zig
5. [playground](https://playground.zigtools.org/)
6. [zvm](https://github.com/ziglang/zvm)
7. zig init, zig init-exe
   zig build, zig build-exe
   zig cc test.c, zig test mytest.zig, zig run my.zig


### c librarys
1. [raylib](https://www.raylib.com/)
2. [ImGui](https://github.com/ocornut/imgui)


### adv topic
1. interface，接口抽象
2. reflect，反射
3. generic，泛型
4. thread pool, 并发编程和通信机制
5. memory manager，内存管理
6. comptime，编译时运行
7. OOP and design pattern，面向对象和设计模式
8. network，网络编程
9. GUI 应用
10. 数据库开发
11. CLI工具

### small project
1. json-server
2. webdis
3. wrk
4. libae
5. httprouter
6. skynet
7. sokit
8. go-sniffer
9. httpie
10. game server

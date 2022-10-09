# MysqlPool
# Mysql-Connect-Pool 

## 项目背景

数据库的连接是一个很耗时的操作，也容易对数据库造成安全隐患。所以，在程序初始化的时候，集中创建多个数据库连接，并把他们集中管理，供程序使用，可以保证较快的数据库读写速度，还更加安全可靠。因此，希望实现一个数据库连接池来帮助项目加快对数据库的操作。

> 参考视频
> [https://www.bilibili.com/video/BV1Fr4y1s7w4?p=1](https://www.bilibili.com/video/BV1Fr4y1s7w4?p=1)

## 开发环境

- 操作系统：`Ubuntu 18.04.6 LTS`
- 编译器：`g++ 7.5.0`
- 编辑器：`vscode`
- 版本控制：`git`
- 项目构建：`cmake 3.10.2`

## 如何运行

登录 MySQL

```shell
mysql -u root -p 123456
```

执行数据库脚本

```shell
source test.sql
```

运行 cmake

```shell
cd ./build && cmake ..
```

此时 cmake 会构建整个项目

```shell
-- The C compiler identification is GNU 7.5.0
-- The CXX compiler identification is GNU 7.5.0
-- Check for working C compiler: /usr/bin/cc
-- Check for working C compiler: /usr/bin/cc -- works
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Detecting C compile features
-- Detecting C compile features - done
-- Check for working CXX compiler: /usr/bin/c++
-- Check for working CXX compiler: /usr/bin/c++ -- works
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Configuring done
-- Generating done
-- Build files have been written to: /home/shang/code/C++/github-project/student-work-project/sql-connect-pool/my_sql_pool/build
```

之后会在当前 build 目录下生成 Makefile 文件。

```shell
make
```

生成文件会在 bin 目录下，我们需要进入 bin 目录执行文件，在这之前，你还需要更改配置文件。配置文件路径在 `bin` 目录下。

```shell
cd ../bin && ./main
```

## 为什么需要MySQL连接池

数据库的连接是一个很耗时的操作，也容易对数据库造成安全隐患。所以，在程序初始化的时候，集中创建多个数据库连接，并把他们集中管理，供程序使用，可以保证较快的数据库读写速度，还更加安全可靠。

在不使用 MySQL 连接池的情况下访问数据库，那么每一次创建数据库连接都需要经过如下步骤：

1. TCP 建立连接的三次握手（客户端与 MySQL 服务器的连接基于 TCP 协议）
2. MySQL 认证的三次握手
3. 真正的 SQL 执行
4. MySQL 的关闭
5. TCP 的四次握手关闭

![1665327079(1).png](https://syz-picture.oss-cn-shenzhen.aliyuncs.com/D:%5CPrograme%20Files(x86)%5CPicGo1665327082304-9b3fbc3e-b0d9-4eac-bcbc-418b381ddea8.png)

可以看到不使用数据库连接池需要经过许多的耗时操作，如果使用数据库连接池可以避免部分操作，加快访问速度

![1665327138(1).png](https://syz-picture.oss-cn-shenzhen.aliyuncs.com/D:%5CPrograme%20Files(x86)%5CPicGo1665327140913-5fc52739-eabc-4af6-9eb9-21a517afeec3.png)

## MySQL接口封装

我们使用 MySQL 经常进行哪些操作？首先肯定要连接数据库，然后我们会对数据库进行增删改查操作。高级操作还会涉及到事务和回滚操作。这些功能 MySQL 都为我们提供了 C API，我们需要设计一个 MysqlConn 类进一步封装这些接口。

### MySQL重要API

#### mysql_init()

分配或初始化与 mysql_real_connect() 相适应的 MYSQL 对象。如果 mysql 是 NULL 指针，该函数将分配、初始化、并返回新对象。否则，将初始化对象，并返回对象的地址。如果 mysql_init() 分配了新的对象，当调用 mysql_close() 来关闭连接时。将释放该对象。

```cpp
MYSQL *mysql_init(MYSQL *mysql)
```

#### mysql_close()

关闭前面打开的连接。如果句柄是由 mysql_init() 或 mysql_connect() 自动分配的，mysql_close() 还将解除分配由 mysql 指向的连接句柄。

```cpp
void mysql_close(MYSQL *mysql)
```

#### mysql_connect()

该函数已过时。最好使用mysql_real_connect()取而代之。

mysql_connect() 试图建立与运行在主机上的MySQL数据库引擎的连接。在能够执行任何其他 API 函数之前，mysql_connect() 必须成功完成。

这些参数的意义与mysql_real_connect()的对应参数的意义相同，差别在于连接参数可以为NULL。在这种情况下，C API将自动为连接结构分配内存，并当调用 mysql_close() 时释放分配的内存。

如果连接成功，返回MYSQL*连接句柄。如果连接失败，返回NULL。对于成功的连接，返回值与第1个参数的值相同。

```cpp
MYSQL *mysql_connect(MYSQL *mysql, const char *host, const char *user, const char *passwd)
```

#### mysql_query()

执行由「Null 终结的字符串」查询指向的 SQL 查询。正常情况下，字符串必须包含 1 条 SQL 语句，而且不应为语句添加终结分号`‘;’`或`\g`。mysql_query 功能强大，也可以执行插入等 SQL 语句。

如果查询成功，返回0。如果出现错误，返回非0值。

```cpp
int mysql_query(MYSQL *mysql, const char *query)
```

#### mysql_store_result()

我们查询成功的结构会被储存到 MYSQL_RES 结果集中，我们需要检索此结果集获取我们想要的结果。使用 mysql_store_result 从 MYSQL 连接中获取结果集

```cpp
MYSQL_RES *mysql_store_result(MYSQL *mysql)
```

#### mysql_fetch_row()

检索结果集的下一行。在 mysql_store_result() 之后使用时，如果没有要检索的行，mysql_fetch_row() 返回NULL。

我们查询 MySQL 得到的是一行行的形式，我们取出结果也是一行行的取出，我们还可以获取其中的字段值。

```cpp
MYSQL_ROW mysql_fetch_row(MYSQL_RES *result)
```

#### mysql_fetch_field()

返回采用 MYSQL_FIELD 结构的结果集的列。重复调用该函数，以检索关于结果集中所有列的信息。未剩余字段时，mysql_fetch_field() 返回 NULL。

```cpp
MYSQL_FIELD *mysql_fetch_field(MYSQL_RES *result)
```

### MysqlConn

MysqlConn 有如下方法：

1. 连接数据库
2. 更新操作
3. 查询操作
4. 事务操作
5. 刷新起始时间

```cpp
class MysqlConn
{
public:
    // 初始化数据库连接
    MysqlConn();
    // 释放数据库连接
    ~MysqlConn();
    // 连接数据库
    bool connect(const std::string& user, const std::string& passwd, const std::string dbName, const std::string& ip, const unsigned int& port = 3306);
    // 更新数据库：包括 insert update delete 操作
    bool update(const std::string& sql);
    // 查询数据库
    bool query(const std::string& sql);
    // 遍历查询得到的结果集
    bool next();
    // 得到结果集中的字段值
    std::string value(int index);
    // 事务操作
    bool transaction();
    // 提交事务
    bool commit();
    // 事务回滚
    bool rollbock();
    // 刷新起始的空闲时间点
    void refreshAliveTime();
    // 计算连接存活的总时长
    long long getAliveTime();

private:
    void freeResult();
    MYSQL* conn_ = nullptr;
    MYSQL_RES* result_ = nullptr;
    MYSQL_ROW row_ = nullptr;
    // 绝对始终
    std::chrono::steady_clock::time_point m_alivetime;
};
```

#### 初始化数据库连接

初始化数据库连接，成员变量保存数据库连接。设置字符编码为 utf8。

```cpp
MysqlConn::MysqlConn()
{
    conn_ = mysql_init(nullptr);
    mysql_set_character_set(conn_, "utf8"); 
}
```

#### 连接数据库

我们需要制定指定初始化后的连接，数据库 IP 地址，登录用户名，登录密码，访问的数据库名，端口号。

```cpp
bool MysqlConn::connect(const std::string& user, const std::string& passwd, const std::string dbName, const std::string& ip, const unsigned int& port)
{
    // 尝试与运行在主机上的MySQL数据库引擎建立连接
    MYSQL* ptr = mysql_real_connect(conn_, ip.c_str(), user.c_str(), passwd.c_str(), dbName.c_str(), port, nullptr, 0);
    return ptr != nullptr;
}
```

#### 释放连接

在连接不为空情况下，调用 mysql_close 释放连接。释放之后记得释放保存的结果集。

```cpp
// 释放数据库连接
MysqlConn::~MysqlConn()
{
    if (conn_ != nullptr) {
        mysql_close(conn_);
    }
    // 释放结果集
    freeResult();
}
```

#### 数据库更新操作

我们直接传入 SQL 语句，使用 mysql_query 接口调用 SQL 语句，返回布尔类型。

```cpp
bool MysqlConn::update(const std::string& sql)
{
    if (mysql_query(conn_, sql.c_str()))
    {
        return false;
    }
    return true;
}
```

#### 数据库查询操作

我们调用 mysql_query 进行查询操作，查询结果会保存到数据库结果集 MYSQL_RES 中。我们还需要调用 mysql_store_result 获取该连接的结果集。

之后获取值的相关操作会利用到结果集 result_。

```cpp
bool MysqlConn::query(const std::string& sql)
{
    // 查询前确保结果集为空
    freeResult();
    if (mysql_query(conn_, sql.c_str()))
    {
        return false;
    }
    // 储存结果集(这是一个二重指针)
    result_ = mysql_store_result(conn_);
    return true;
}
```

我们的结果集中保存了数据，结果集本质上是一个多维数组，我们也是用二级指针指向的。因此，我们可以遍历结果集，这里是调用 mysql_fetch_row 函数，获取此结果集中的一行。如果我们不断地调用，就可以读完整个结果。

```cpp
// 遍历查询得到的结果集
bool MysqlConn::next()
{
    if (result_ != nullptr)
    {
        row_ = mysql_fetch_row(result_);
        if (row_ != nullptr)
        {
            return true;
        }
    }
    return false;
}
```

获取结果集中的字段值，这里有一个细节，我们可能在数据库中存储二进制数据。这里面可能会包含 `\0` 等字符，在 C 语言字符串中这就等于分隔符了。因此，我们直接读取可能会漏掉数据，我们应该先获取字段值的长度，然后按照这个长度构造字符串。

```cpp
// 得到结果集中的字段值
std::string MysqlConn::value(int index)
{
    int rowCount = mysql_num_fields(result_);
    if (index >= rowCount || index < 0)
    {
        // 获取字段索引不合法，返回空字符串
        return std::string();
    }
    // 考虑到储存的可能是二进制字符串，其中含有'\0'
    // 那么我们无法获得完整字符串，因此需要获取字符串头指针和字符串长度
    char* val = row_[index];
    unsigned long length = mysql_fetch_lengths(result_)[index];
    return std::string(val, length);
}

```

#### 事务相关操作

```cpp
// 事务操作
bool MysqlConn::transaction()
{
    // true  自动提交
    // false 手动提交
    return mysql_autocommit(conn_, false);
}

// 提交事务
bool MysqlConn::commit()
{
    return mysql_commit(conn_);
}

// 事务回滚
bool MysqlConn::rollbock()
{
    return mysql_rollback(conn_);
}
```

#### 刷新该连接的时间

我们的数据库连接池可以动态创建和释放数据库连接，这就需要记录每个连接的存活时间了。如果某个连接时间过长且未被使用，这就会造成资源浪费。我们需要回收，因此在连接的属性中会记有记录时间属性的变量。

我们使用 chrono 的 now 方法获取时间戳，并保存此时间戳。

```cpp
// 刷新起始的空闲时间点
void MysqlConn::refreshAliveTime()
{
    // 获取时间戳
    m_alivetime = std::chrono::steady_clock::now();
}
```

当我们要定时处理过久的连接时候，就会调用此函数。我们会得到该连接存活的时长，这是通过两个时间戳差得到的。

```cpp
// 计算连接存活的总时长
long long MysqlConn::getAliveTime()
{
    // 获取时间段（当前时间戳 - 创建时间戳）
    std::chrono::nanoseconds res = std::chrono::steady_clock::now() - m_alivetime;
    // 纳秒 -> 毫秒，高精度向低精度转换需要duration_cast
    std::chrono::milliseconds millsec = std::chrono::duration_cast<std::chrono::milliseconds>(res);
    // 返回毫秒数量
    return millsec.count();
}
```

## 连接池封装

我们现在封装了 MySQL 连接，现在正式开始封装 MySQL 连接池。连接池应该做到以下事情，管理连接，获取连接

### 单例模式

我们只需要一个连接池来管理即可，这里使用单例模式。单例模式有许多种实现，这里利用 C++ 11 的 static 特性实现单例模式。C++ 11 保证 static 变量是线程安全的，并且被 static 关键字修饰的变量只会被创建时初始化，之后都不会。

我们只能通过 getConnectionPool 静态函数获取唯一的连接池对象，外部不能调用连接池的构造函数。因此，我们需要将构造函数私有化。相应的，拷贝构造函数，拷贝赋值运算符以及移动构造函数都不能被调用。C++ 11 使用 delete 关键字即可实现。

```cpp
class ConnectionPool
{
public:
    static ConnectionPool* getConnectionPool();
	...

private:
    ConnectionPool();
    ConnectionPool(const ConnectionPool& obj) = delete;
    ConnectionPool(const ConnectionPool&& obj) = delete;
    ConnectionPool& operator=(const ConnectionPool& obj) = delete;
	...
};

ConnectionPool* ConnectionPool::getConnectionPool()
{
    static ConnectionPool pool;
    return &pool;
}
```

### 连接池构造时需要做的事情

1. 解析 JSON 配置文件
2. 创建新的数据库连接
3. 开启线程执行任务
   1. 必要时创建新连接
   2. 必要时销毁连接

```cpp
ConnectionPool::ConnectionPool()
{
    parseJsonFile();

    for (int i = 0; i < minSize_; ++i)
    {
        addConnection();
    }
    // 开启新线程执行任务
    std::thread producer(&ConnectionPool::produceConnection, this);
    std::thread recycler(&ConnectionPool::recycleConnection, this);
    // 设置线程分离，不阻塞在此处
    producer.detach();
    recycler.detach();
}
```

#### 解析JSON配置文件

我们的连接池保存了需要连接的数据库的信息，比如登录用户名，用户密码等。我们需要将这些信息写到配置文件中，这里用 JSON 格式储存。我使用的是 JSON FOR MODERN C++ 项目解析的 JSON 文件，只需要包含 json.hpp 这一个头文件就可以使用，方便移植。

```cpp
bool ConnectionPool::parseJsonFile()
{
    std::ifstream file("conf.json");
    json conf = json::parse(file);

    ip_ = conf["ip"];
    user_ = conf["userName"];
    passwd_ = conf["password"];
    dbName_ = conf["dbName"];
    port_ = conf["port"];
    minSize_ = conf["minSize"];
    maxSize_ = conf["maxSize"];
    timeout_ = conf["timeout"];
    maxIdleTime_ = conf["maxIdleTime"];
    return true;
}
```

#### 创建数据库连接

然后我们需要创建一定数量的数据库连接，数据库连接池会维持一个最小连接数量，如果有必要会在后面继续创建数据库连接，但是不会超过维护的最大连接数。

这里就是调用我们之前封装好的接口，创建数据库连接，并记录该连接的时间戳。

```cpp
void ConnectionPool::addConnection()
{
    MysqlConn* conn = new MysqlConn;
    conn->connect(user_, passwd_, dbName_, ip_, port_);
    conn->refreshAliveTime();    // 刷新起始的空闲时间点
    connectionQueue_.push(conn); // 记录新连接
}
```

#### 创建新线程执行后台任务

数据库连接池创建了连接之后，还需要执行以下任务。

1. 当数据库连接池的连接数目不够的时候，需要有一个线程在后台默默的创建新的连接。
2. 我们还需要有一个线程可以回收数据库连接

produceConnection() 当数据库连接的数量大于等于最小连接数的时候，我们是不需要创建新连接。这个时候 producer 线程就会被阻塞。否则调用 addConnection() 创建新的数据库连接，并唤醒所有被阻塞的线程。

```cpp
void ConnectionPool::produceConnection()
{
    while (true)
    {
        // RALL手法封装的互斥锁，初始化即加锁，析构即解锁
        std::unique_lock<std::mutex> locker(mutex_);
        while (connectionQueue_.size() >= minSize_)
        {
            cond_.wait(locker);
        } 
        // 如果可用连接数不大于维持的最小连接数，我们就需要创建新的连接
        addConnection();
        // 唤醒被阻塞的线程
        cond_.notify_all();
    }
}
```

recycleConnection() 在后台周期性的做检测工作，每 500 毫秒检测一次数据库连接池中所维持连接的数量，如果超过了最大的连接数则要判断连接池队列里各个连接的存活时间，如果存活时间超过限制则销毁改连接。

```cpp
// 销毁多余的数据库连接
void ConnectionPool::recycleConnection()
{
    while (true)
    {
        // 周期性的做检测工作，每500毫秒（0.5s）执行一次
        std::this_thread::sleep_for(std::chrono::microseconds(500));
        std::lock_guard<std::mutex> locker(mutex_);
        while (connectionQueue_.size() > minSize_)
        {
            MysqlConn* conn = connectionQueue_.front();
            if (conn->getAliveTime() >= maxIdleTime_)
            {
                // 存在时间超过设定值则销毁
                connectionQueue_.pop();
                delete conn;
            }
            else
            {
                // 按照先进先出顺序，前面的没有超过后面的肯定也没有
                break;
            }
        }
    }
}
```

注意，上述两个函数都需用到互斥锁，这里使用的是 lock_guard，其使用 RALL 手法封装互斥锁。在一个作用域内，我们`std::unique_lock<std::mutex> locker(mutex_);`，那么 locker 初始化即上锁，出作用域则被析构并释放锁。lock_guard 可以更好的管理 mutex 资源，避免忘记释放锁或者出现异常情况提前退出。

### 获取连接

我们的线程池对外的接口之一就是 getConnection 函数，我们通过此函数从数据库连接池中获取一个可用的数据库连接，从而避免了重复创建新连接。

在获取连接的时候需要考虑连接池有没有可用的连接，当连接池可用连接为空时，会阻塞一段时间。这个时候就涉及到了之前的 produceConnection 函数了。如果可用连接不够用且维护连接数没到限制值，则会创建新连接。创建成功后会唤醒在此处阻塞的线程们。

还有一件事情，我们要维护连接。因此，不仅要做到能给出连接，还要做到能回收连接。我们该如何回收连接呢？这里我们使用的是智能指针的特性解决的，我们可以用一个智能指针管理连接资源，将此智能指针传出给外面的调用者。此智能指针绑定了自定义的删除器，当其析构之后只就会执行我们的删除器代码。

删除器要做的事情就是将此连接重新加入 connectionQueue 中，然后重新设置这个连接的时间戳。

```cpp
std::shared_ptr<MysqlConn> ConnectionPool::getConnection()
{
    std::unique_lock<std::mutex> locker(mutex_);
    while (connectionQueue_.empty())
    {
        // 如果为空，需要阻塞一段时间，等待新的可用连接
        if (std::cv_status::timeout == cond_.wait_for(locker, std::chrono::milliseconds(timeout_)))
        {
            // std::cv_status::timeout 表示超时
            if (connectionQueue_.empty())
            {
                continue;
            }
        }
    }
    // 有可用的连接
    // 如何还回数据库连接？
    // 使用共享智能指针并规定其删除器
    // 规定销毁后调用删除器，在互斥的情况下更新空闲时间并加入数据库连接池
    std::shared_ptr<MysqlConn> connptr(connectionQueue_.front(), 
        [this](MysqlConn* conn) {
            std::lock_guard<std::mutex> locker(mutex_);
            conn->refreshAliveTime();
            connectionQueue_.push(conn);
        });
    connectionQueue_.pop();
    cond_.notify_all();
    return connptr;
}
```

## 性能测试

在测试前先进入数据库，创建一个测试用的数据库和表。

```sql
CREATE DATABASE test;

USE test;

CREATE TABLE user
(
    id      int       NOT NULL AUTO_INCREMENT,
    name    char(50)  NOT NULL ,
    address char(50)  NOT NULL ,
    PRIMARY KEY (id)
) ENGINE=InnoDB;
```

### MysqlConn功能测试

```cpp
// 查询测试
int query()
{
    MysqlConn conn;
    conn.connect("root", "200166_Shangjkld", "test", "127.0.0.1");
    string sql = "insert into user values(1, 'zhang san', '221B')";
    bool flag = conn.update(sql);
    cout << "flag value:  " << flag << endl;

    sql = "select * from user";
    conn.query(sql);
    // 从结果集中取出一行
    while (conn.next())
    {
        // 打印每行字段值
        cout << conn.value(0) << ", "
            << conn.value(1) << ", "
            << conn.value(2) << ", "
            << conn.value(3) << endl;
    }
    return 0;
}
```

### 数据库连接池性能测试

测试分成几个方面：

1. 单线程不使用数据库连接池
2. 单线程使用数据库连接池
3. 多线程不使用数据库连接池
4. 多线程使用数据库连接池

然后分别测试这几种方式操作数据库的总耗时，我们会往表里插入 5000 条数据。

使用数据库连接池和不使用连接池的代码

```cpp
// 非连接池
void op1(int begin, int end)
{
    for (int i = begin; i < end; ++i)
    {
        MysqlConn conn;
        conn.connect("root", "200166_Shangjkld", "test", "127.0.0.1");
        char sql[1024] = { 0 };
        snprintf(sql, sizeof(sql), "insert into user values(%d, 'zhang san', '221B')", i);
        conn.update(sql);
    }
}

// 连接池
void op2(ConnectionPool* pool, int begin, int end)
{
    for (int i = begin; i < end; ++i)
    {
        shared_ptr<MysqlConn> conn = pool->getConnection();
        char sql[1024] = { 0 };
        snprintf(sql, sizeof(sql), "insert into user values(%d, 'zhang san', '221B')", i);
        conn->update(sql);
    }
}
```

单线程下调用

```c++
// 单线程
void test1()
{
#if 0
    // 非连接池, 单线程, 用时: 34127689958 纳秒, 34127 毫秒
    steady_clock::time_point begin = steady_clock::now();
    op1(0, 5000);
    steady_clock::time_point end = steady_clock::now();
    auto length = end - begin;
    cout << "非连接池, 单线程, 用时: " << length.count() << " 纳秒, "
        << length.count() / 1000000 << " 毫秒" << endl;
#else
    // 连接池, 单线程, 用时: 19413483633 纳秒, 19413 毫秒
    ConnectionPool* pool = ConnectionPool::getConnectionPool();
    steady_clock::time_point begin = steady_clock::now();
    op2(pool, 0, 5000);
    steady_clock::time_point end = steady_clock::now();
    auto length = end - begin;
    cout << "连接池, 单线程, 用时: " << length.count() << " 纳秒, "
        << length.count() / 1000000 << " 毫秒" << endl;

#endif
}
```

多线程下调用

```cpp
// 多线程
void test2()
{
#if 0
    // 非连接池, 多单线程, 用时: 15702495964 纳秒, 15702 毫秒
    MysqlConn conn;
    conn.connect("root", "200166_Shangjkld", "test", "127.0.0.1");
    steady_clock::time_point begin = steady_clock::now();
    std::thread t1(op1, 0, 1000);
    std::thread t2(op1, 1000, 2000);
    std::thread t3(op1, 2000, 3000);
    std::thread t4(op1, 3000, 4000);
    std::thread t5(op1, 4000, 5000);
    t1.join();
    t2.join();
    t3.join();
    t4.join();
    t5.join();
    steady_clock::time_point end = steady_clock::now();
    auto length = end - begin;
    cout << "非连接池, 多单线程, 用时: " << length.count() << " 纳秒, "
        << length.count() / 1000000 << " 毫秒" << endl;

#else
    // 连接池, 多单线程, 用时: 6076443405 纳秒, 6076 毫秒
    ConnectionPool* pool = ConnectionPool::getConnectionPool();
    steady_clock::time_point begin = steady_clock::now();
    std::thread t1(op2, pool, 0, 1000);
    std::thread t2(op2, pool, 1000, 2000);
    std::thread t3(op2, pool, 2000, 3000);
    std::thread t4(op2, pool, 3000, 4000);
    std::thread t5(op2, pool, 4000, 5000);
    t1.join();
    t2.join();
    t3.join();
    t4.join();
    t5.join();
    steady_clock::time_point end = steady_clock::now();
    auto length = end - begin;
    cout << "连接池, 多单线程, 用时: " << length.count() << " 纳秒, "
        << length.count() / 1000000 << " 毫秒" << endl;

#endif
}
```
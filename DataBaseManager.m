//
//  DataBaseManager.m
//  test
//
//  Created by feerie luxe on 16/4/20.
//  Copyright © 2016年 NN. All rights reserved.
//

#import "DataBaseManager.h"
#import "FMDatabase.h"
#import <objc/runtime.h>

@interface DataBaseManager ()
{
    FMDatabase * _dataBase;
    //数据库打开失败错误
    NSError * _dataBaseOpenFailureError;
    //数据库执行sql语句失败错误
    NSError * _dataBaseExecuteSqlFailureError;
}
@end

@implementation DataBaseManager


#pragma mark    初始化方法
-(instancetype)init
{
    if (self = [super init])
    {
        _dataBase = [FMDatabase databaseWithPath:[self dataBasePath]];
//        NSLog(@"%@",[self dataBasePath]);
        _dataBaseOpenFailureError = [[NSError alloc] initWithDomain:@"数据库打开失败" code:-1000 userInfo:nil];
        _dataBaseExecuteSqlFailureError = [[NSError alloc] initWithDomain:@"sql语句执行失败" code:-1002 userInfo:nil];
    }
    return self;
}


#pragma mark     数据库路径
-(NSString *)dataBasePath
{
    NSString * documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return [documentPath stringByAppendingPathComponent:@"data.db"];
}


#pragma mark      获取单例DataBaseManager
+(instancetype)sharedDataBaseManager
{
    static DataBaseManager * dataBaseManager = nil;
    
    static dispatch_once_t onceTokenOfDataBaseManager;
    
    dispatch_once(&onceTokenOfDataBaseManager, ^{
        dataBaseManager = [[DataBaseManager alloc] init];
    });
    
    return dataBaseManager;
}

#pragma mark    插入一个对象
-(void)insertObjectToDataBaseWithObject:(id)object failure:(ExecuteSqlErrorBlock)block
{
    //判断打开数据库是否成功
    if (![_dataBase open])
    {
        block(_dataBaseOpenFailureError);
         [_dataBase close];
        return;
    }
    
    NSString * objectName = NSStringFromClass([object class]);
    //判断表是否存在
    if (![self isExistTableInDataBaseWithTableName:objectName])
    {
        //不存在 创建该表
        if (![self createTabelInDataBaseWithObject:object])
        {
            NSError * error = [[NSError alloc] initWithDomain:@"创建表失败" code:-1001 userInfo:nil];
            block(error);
             [_dataBase close];
            return;
        }
    }
    
    //拼接sql语句
    NSMutableString * sql = [NSMutableString stringWithFormat:@"insert into %@(",objectName];
    
    NSMutableString * values = [NSMutableString stringWithFormat:@"values("];
    
    NSArray * properties = [self propertiesFromObject:object];
    
    for (int i = 0; i < properties.count; i++)
    {
        id value = [object valueForKey:properties[i]];
        
        if (i == properties.count - 1)
        {
            [sql appendFormat:@"%@ )",properties[i]];
            [values appendFormat:@"'%@' )",value];
        }
        else
        {
            [sql appendFormat:@"%@ ,",properties[i]];
            [values appendFormat:@"'%@' ,",value];
        }
    }
    
    [sql appendString:values];
    
    //执行操作
    if(![_dataBase executeUpdate:sql])
    {
        block(_dataBaseExecuteSqlFailureError);
        [_dataBase close];
        return;
    }
    
    [_dataBase close];
}

#pragma mark      根据类名查询 并取出所有对象
-(void)queryAllObjectFromDataBaseWithObject:(id)obj success:(ExecuteSqlSuccessBlock)successBlock failure:(ExecuteSqlErrorBlock)failureBlock
{
    //打开数据库
    if(![_dataBase open])
    {
        failureBlock(_dataBaseOpenFailureError);
        [_dataBase close];
        return;
    }
    
    NSString * obejctName = NSStringFromClass([obj class]);
    
    //拼接sql语句
    NSString * sql = [NSString stringWithFormat:@"select * from %@",obejctName];
    
    //执行
    FMResultSet * results = [_dataBase executeQuery:sql];
    if (!results)
    {
        failureBlock(_dataBaseExecuteSqlFailureError);
        [_dataBase close];
        return;
    }
    
    successBlock([self modelsFromFMResultSet:results Object:obj]);
    
    [_dataBase close];
}


#pragma mark     删除某个类的表
-(void)deleteAllObjectInDatabaseWithObject:(id)object failure:(ExecuteSqlErrorBlock)block
{
    if (![_dataBase open])
    {
        block(_dataBaseOpenFailureError);
        return;
    }
    
    NSString * sql = [NSString stringWithFormat:@"delete from %@",NSStringFromClass([object class])];
    
    if (![_dataBase executeUpdate:sql])
    {
        block(_dataBaseExecuteSqlFailureError);
        [_dataBase close];
        return;
    }
    
    [_dataBase close];
}

#pragma mark     删除表中某一个对象
-(void)deleteObjectFromTableWithObject:(id)object PropertyName:(NSString *)name andPropertyValue:(NSString *)value failure:(ExecuteSqlErrorBlock)block
{
    if (![_dataBase open])
    {
        block(_dataBaseOpenFailureError);
        return;
    }
    
    NSString * sql = [NSString stringWithFormat:@"delete from %@ where %@ = '%@'",NSStringFromClass([object class]),name,value];
    
    if (![_dataBase executeUpdate:sql])
    {
        block(_dataBaseExecuteSqlFailureError);
        [_dataBase close];
        return;
    }
    
    [_dataBase close];
}

#pragma mark    根据类名查询 获取某个对象 查询某个属性是否存在
-(void)existsPropertyOfObjectInDataBaseFromObject:(id)obj withPropertyName:(NSString *)property andPropretyValue:(NSString *)value success:(ExecuteSqlSuccessBlock)successBlock failure:(ExecuteSqlErrorBlock)failureBlock
{
    if (![_dataBase open])
    {
        failureBlock(_dataBaseOpenFailureError);
        return;
    }
    
    if(![self isExistTableInDataBaseWithTableName:NSStringFromClass([obj class])])
    {
        NSError * error = [[NSError alloc] initWithDomain:@"表不存在" code:-1004 userInfo:nil];
        failureBlock(error);
        [_dataBase close];
        return;
    }
    
    NSString * sql = [NSString stringWithFormat:@"select * from %@ where %@ = '%@'",NSStringFromClass([obj class]),property,value];
    
    if (![_dataBase executeQuery:sql])
    {
        failureBlock(_dataBaseExecuteSqlFailureError);
        [_dataBase close];
        return;
    }
    
    FMResultSet * results = [_dataBase executeQuery:sql];
    successBlock([self modelsFromFMResultSet:results Object:obj]);
}

#pragma mark      通用方法
#pragma mark      获取某类的所有属性名称
-(NSArray *)propertiesFromObject:(id)object
{
    //接收数组
    NSMutableArray * propertiesArray = [NSMutableArray array];
    
    /** runtime */
    //获取属性
    unsigned int outCount;
    
    objc_property_t * properties = class_copyPropertyList([object class], &outCount);
    
    //遍历 将字符串转为OC对象
    for (int i = 0; i < outCount; i++)
    {
        objc_property_t t = properties[i];
        const char * propertyName = property_getName(t);
        
        [propertiesArray addObject:[NSString stringWithUTF8String:propertyName]];
    }
    
    return [propertiesArray copy];
}

#pragma mark    判断某类对象的表是否存在
-(BOOL)isExistTableInDataBaseWithTableName:(NSString *)objName
{
    NSString * sql = [NSString stringWithFormat:@"select name from sqlite_master where type = 'table' and name = '%@'",objName];
    
    FMResultSet * result = [_dataBase executeQuery:sql];
    
    return [result next];
}

#pragma mark     创建表
-(BOOL)createTabelInDataBaseWithObject:(id)object
{
    if(![_dataBase open])
    {
        return NO;
    }
    //获取属性数组
    NSArray * properties = [self propertiesFromObject:object];
    
    //拼接sql语句
    NSMutableString * sql = [NSMutableString stringWithFormat:@"create table if not exists %@(id integer primary key autoincrement",NSStringFromClass([object class])];
    
    for (NSString * str in properties)
    {
        [sql appendFormat:@",%@ text",str];
    }
    [sql appendFormat:@")"];
    
    BOOL isCreate = [_dataBase executeUpdate:sql];
    
    [_dataBase close];
    return isCreate;
}


#pragma mark -删除表中某一个对象
-(BOOL)deleteObjectFromTableWithTypeName:(NSString *)type andObjectName:(NSString *)name
{
    if (![_dataBase open])
    {
        return NO;
    }
    
    NSString * sql = [NSString stringWithFormat:@"delete from %@ where name = '%@'",type,name];
    
    BOOL isOK = [_dataBase executeUpdate:sql];
    
    [_dataBase close];
    
    return isOK;
}

#pragma mark    根据FMResultSer获取查询出的对象数组
-(NSArray *)modelsFromFMResultSet:(FMResultSet *)results Object:(id)obj
{
    //初始化数组存储取出的对象
    NSMutableArray * objects = [NSMutableArray array];
    
    NSArray * properties = [self propertiesFromObject:obj];
    
    while (results.next)
    {
        id object = [[NSClassFromString(NSStringFromClass([obj class])) alloc ] init];
        
        for (NSString * propertyName in properties)
        {
            [object setValue:[results stringForColumn:propertyName] forKey:propertyName];
        }
        
        [objects addObject:object];
    }
    
    return [objects copy];
}
@end

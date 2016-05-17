//
//  DataBaseManager.h
//  test
//
//  Created by feerie luxe on 16/4/20.
//  Copyright © 2016年 NN. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^ExecuteSqlErrorBlock)(NSError * error);
typedef void(^ExecuteSqlSuccessBlock)(id result);
@interface DataBaseManager : NSObject

/** 获取单例DataBaseManager */
+(instancetype)sharedDataBaseManager;


#pragma mark    数据库相关操作

#pragma mark    数据库 增
/** 插入一个对象 */
-(void)insertObjectToDataBaseWithObject:(id)object failure:(ExecuteSqlErrorBlock)block;

#pragma mark    数据库 删
/** 删除某个对象的表 */
- (void)deleteAllObjectInDatabaseWithObject:(id)object failure:(ExecuteSqlErrorBlock)block;
/** 删除表中某一个对象 */
-(void)deleteObjectFromTableWithObject:(id)object PropertyName:(NSString *)name andPropertyValue:(NSString *)value failure:(ExecuteSqlErrorBlock)block;

#pragma mark    数据库 查
/** 根据类名查询 并取出所有对象 */
-(void)queryAllObjectFromDataBaseWithObject:(id)obj success:(ExecuteSqlSuccessBlock)successBlock failure:(ExecuteSqlErrorBlock)failureBlock;
/** 根据类名查询 获取某个对象 查询某个属性是否存在 */
-(void)existsPropertyOfObjectInDataBaseFromObject:(id)obj withPropertyName:(NSString *)property andPropretyValue:(NSString *)value success:(ExecuteSqlSuccessBlock)successBlock failure:(ExecuteSqlErrorBlock)failureBlock;
/** 获取表的行数 */
-(void)queryCountFromTableWithObject:(id)object success:(ExecuteSqlSuccessBlock)successBlock failure:(ExecuteSqlErrorBlock)failureBlock;
/** 获取指定行数的数据 从 endRow 倒数 endRow-beginRow 个对象*/
-(void)queryObjectsFromTable:(id)object begin:(NSInteger)beginRow end:(NSInteger)endRow success:(ExecuteSqlSuccessBlock)successBlock failure:(ExecuteSqlErrorBlock)failureBlock;

#pragma mark    数据库 改


@end

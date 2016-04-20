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
/** 插入一个对象 */
-(void)insertObjectToDataBaseWithObject:(id)object failure:(ExecuteSqlErrorBlock)block;
/** 根据类名查询 并取出所有对象 */
-(void)queryAllObjectFromDataBaseWithObject:(id)obj success:(ExecuteSqlSuccessBlock)successBlock failure:(ExecuteSqlErrorBlock)failureBlock;
/** 根据类名查询 获取某个对象 查询某个属性是否存在 */
-(void)existsPropertyOfObjectInDataBaseFromObject:(id)obj withPropertyString:(NSString *)property andPropretyOfObect:(NSString *)value success:(ExecuteSqlSuccessBlock)successBlock failure:(ExecuteSqlErrorBlock)failureBlock;
/** 删除某个对象的表 */
- (void)deleteAllObjectInDatabaseWithObject:(id)object failure:(ExecuteSqlErrorBlock)block;
/** 删除表中某一个对象 */
-(void)deleteObjectFromTableWithObject:(id)object andPropertyString:(NSString *)property failure:(ExecuteSqlErrorBlock)block;
@end

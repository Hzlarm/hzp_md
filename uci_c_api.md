

https://lxr.openwrt.org/source/uci/

常用API
1、uci_alloc_context: 动态申请一个uci上下文结构
struct uci_context *uci_alloc_context(void);

2、uci_free_context: 释放由uci_alloc_context申请的uci上下文结构且包括它的所有数据
void uci_free_context(struct uci_context *ctx);

3、uci_lookup_ptr：由给定的元组查找元素
int uci_lookup_ptr(struct uci_context *ctx, struct uci_ptr *ptr, char *str, bool extended);

4、uci_set ：写入配置
int uci_set(struct uci_context *ctx, struct uci_ptr *ptr);

5、uci_unload : 卸载包
int uci_unload(struct uci_context *ctx, struct uci_package *p);

6、uci_commit : 将缓冲区的更改保存到配置文件 还有uci_save ,有区别
int uci_commit(struct uci_context *ctx, struct uci_package **p, bool overwrite);

7、uci_foreach_element : 遍历uci的每个节点

8、uci_perror : 获取最后一个uci错误的错误字符串
void uci_perror(struct uci_context *ctx, const char *str);


9、uci_add_section：配置一个节点的值，如果节点不存在则创建
int uci_add_section(struct uci_context *ctx, struct uci_package *p, const char *type, struct uci_section **res);

10、uci_add_list : 追加一个list类型到节点
int uci_add_list(struct uci_context *ctx, struct uci_ptr *ptr);

11、uci_lookup_section : 查看一个节点
uci_section *uci_lookup_section(struct uci_context *ctx, struct uci_package *p, const char *name)

12、uci_lookup_option : 查看一个选项
 uci_option *uci_lookup_option(struct uci_context *ctx, struct uci_section *s, const char *name)

13、int uci_load ：加载配置文件
int uci_load(struct uci_context *ctx, const char *name, struct uci_package **package)









```c
#include "uci.h"

/**
*  @brief 载入配置文件,查找list的值
*/ 
void * seek_list_value(char *file,char *section,char*option)
{
    struct uci_context * ctx = NULL;
    struct uci_package * pkg = NULL;  
    struct uci_element *e;  
    const char *value;
    char *return_value =NULL;
    if (file == NULL || section == NULL || option == NULL){
        return NULL;
    }
    ctx = uci_alloc_context(); // 申请一个UCI上下文.  
    if (UCI_OK != uci_load(ctx, file, &pkg)){
        printf("uci_load %s fail\n",file);
        goto cleanup; //如果打开UCI文件失败,则跳到末尾 清理 UCI 上下文.  
    }
    /*遍历UCI的每一个节*/  
    uci_foreach_element(&pkg->sections, e)  
    {  
        struct uci_section *s = uci_to_section(e);  
        // 将一个 element 转换为 section类型, 如果节点有名字,则 s->anonymous 为 false.  
        // 此时通过 s->e->name 来获取.  
        // 此时 您可以通过 uci_lookup_option()来获取 当前节下的一个值. 
     /*   if(strcmp(section,e->name)==0 ){
            value = uci_lookup_option_string(ctx, s, option);
            if (NULL != value)
                return_value = strdup(value);//如果您想持有该变量值，一定要拷贝一份。当 pkg销毁后value的内存会被释放。
        }*/
        // 如果您不确定是 string类型 可以先使用 uci_lookup_option() 函数得到Option 然后再判断.  
        // Option 的类型有 UCI_TYPE_STRING 和 UCI_TYPE_LIST 两种.  

		// s 为 section.  
		struct uci_option * o = uci_lookup_option(ctx, s, option);  
		if ((NULL != o) && (UCI_TYPE_LIST == o->type)) //o存在 且 类型是 UCI_TYPE_LIST则可以继续.  
		{  
		    struct uci_element *ee;  
			memset(&protoCtx->usbCtx.mount_point[0][0],0,sizeof(char)*MAX_MOUNT_POINT_NUM*MAX_MOUNT_POINT_LEN);
			int i=0;
		    uci_foreach_element(&o->v.list, ee)  
		    {  
		        //这里会循环遍历 list  
		        logw("1'mount_point:%s\n",ee->name);
		        if(strlen(ee->name) < MAX_MOUNT_POINT_LEN){
					strcpy(protoCtx->usbCtx.mount_point[i],ee->name);
		        }
				logw("2'mount_point:%s\n",protoCtx->usbCtx.mount_point[i]);
				i++;
		    }  
		}  

    }  
    uci_unload(ctx, pkg); // 释放 pkg 
cleanup:  
    uci_free_context(ctx);  
    ctx = NULL;  
    return return_value;
}

/**
*  @brief 载入配置文件,并遍历Section. 
*/  
char * seek_value(char *file,char *section,char*option)
{
    struct uci_context * ctx = NULL;
    struct uci_package * pkg = NULL;  
    struct uci_element *e;  
    const char *value;
    char *return_value =NULL;
    if (file == NULL || section == NULL || option == NULL){
        return NULL;
    }
    ctx = uci_alloc_context(); // 申请一个UCI上下文.  
    if (UCI_OK != uci_load(ctx, file, &pkg)){
        printf("uci_load %s fail\n",file);
        goto cleanup; //如果打开UCI文件失败,则跳到末尾 清理 UCI 上下文.  
    }
    /*遍历UCI的每一个节*/  
    uci_foreach_element(&pkg->sections, e)  
    {  
        struct uci_section *s = uci_to_section(e);  
        // 将一个 element 转换为 section类型, 如果节点有名字,则 s->anonymous 为 false.  
        // 此时通过 s->e->name 来获取.  
        // 此时 您可以通过 uci_lookup_option()来获取 当前节下的一个值. 
        if(strcmp(section,e->name)==0 ){
            value = uci_lookup_option_string(ctx, s, option);
            if (NULL != value)
                return_value = strdup(value);//如果您想持有该变量值，一定要拷贝一份。当 pkg销毁后value的内存会被释放。
            //strdup()在内部调用了malloc()为变量分配内存，不需要使用返回的字符串时，需要用free()释放相应的内存空间，否则会造成内存泄漏。
        }
        // 如果您不确定是 string类型 可以先使用 uci_lookup_option() 函数得到Option 然后再判断.  
        // Option 的类型有 UCI_TYPE_STRING 和 UCI_TYPE_LIST 两种.  
    }  
    uci_unload(ctx, pkg); // 释放 pkg 
cleanup:  
    uci_free_context(ctx);  
    ctx = NULL;  
    return return_value;
}


/**
* @brief 修改uci的参数值
*/
int fix_value(char *file,char *section,char*option,char *value)
{

    if(file == NULL || section == NULL || option == NULL || value == NULL){
        return -1;
    }
    struct uci_context * ctx = uci_alloc_context(); //申请上下文  
    struct uci_ptr ptr ={  
        .package = file,
        .section = section,  
        .option = option,  
        .value = value,
    };
    uci_set(ctx,&ptr); //写入配置  
    uci_commit(ctx, &ptr.p, false); //提交保存更改  
    uci_unload(ctx,ptr.p); //卸载包  
    uci_free_context(ctx); //释放上下文
    return 0;
}

/**
* @brief 删除一个option
*/
int delete_option(char *file,char *section,char*option)
{
    if(file == NULL || section == NULL || option == NULL){
        return -1;
    }
    struct uci_context * ctx = uci_alloc_context(); //申请上下文  
    struct uci_ptr ptr ={  
        .package = file,
        .section = section,  
        .option = option,  
    };
    uci_delete(ctx,&ptr); //写入配置  
    uci_commit(ctx, &ptr.p, false); //提交保存更改  
    uci_unload(ctx,ptr.p); //卸载包  
    uci_free_context(ctx); //释放上下文
    return 0;
}

/**
* @brief 删除一个section
*/
int delete_section(char *file,char *section)
{
    if(file == NULL || section == NULL){
        return -1;
    }
    struct uci_context * ctx = uci_alloc_context(); //申请上下文  
    struct uci_ptr ptr ={  
        .package = file,
        .section = section,    
    };
    uci_delete(ctx,&ptr); //写入配置  
    uci_commit(ctx, &ptr.p, false); //提交保存更改  
    uci_unload(ctx,ptr.p); //卸载包  
    uci_free_context(ctx); //释放上下文
    return 0;
}
```


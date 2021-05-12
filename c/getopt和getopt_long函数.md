# linux的命令行解析参数之getopt_long函数

> 在linux中 ,经常使用 GNU C 提供的函数  `getopt、getopt_long、getopt_long_only`  来解析命令行参数。 

```c
//man  getopt_long
NAME
       getopt, getopt_long, getopt_long_only, optarg, optind, opterr, optopt - Parse command-line options

SYNOPSIS
#include <unistd.h>

int getopt(int argc, char * const argv[],
			const char *optstring);

extern char *optarg;
extern int optind, opterr, optopt;

#include <getopt.h>

int getopt_long(int argc, char * const argv[],
			const char *optstring,
			const struct option *longopts, int *longindex);

int getopt_long_only(int argc, char * const argv[],
			const char *optstring,
			const struct option *longopts, int *longindex);
```

### 函数参数

* argc和argv对应main函数的两个参数，直接传入即可。

* `optstring`  表示**短选项**字符串。

  如 `"ab:c::"` 表示是否有 `-a、-b、-c`选项。
  `a`无冒号只表示是选项如 `-a`，`b:`表示后面带参数如 `-b 100`，`c::`表示后面带可选参数(参数与选项之间无空格)如 `-c200` 或 `-c`

* `longopts`  表示长选项结构体。

  ```c
  struct option 
  {  
  	const char *name;    //选项名称
  	int         has_arg; //选项后是否携带参数。
      			//no_argument或0表示不带参数。如 --help
      			//required_argument或1表示带参数。如--dir /home 或 --dir=/home
      			//optional_argument 或2表示可选参数。如--name或--name=Justin
  	int        *flag;  	 //NULL或非NULL
      			//NULL表示getopt_long将返回val值。如 --help返回h
      			//非NULL表示getopt_long将返回0，而flag指针指向val值。
  	int         val;     //表示指定函数找到该选项时的返回值，或者当flag非空时指定flag指向的数据的值val。
      //注意：数组的最后一个元素必须填满0。
  };
  //如：
  static struct option longopts[] = {
  	{ "help", no_argument, NULL, 'h' },
  	{ "version", 0, 0, 'v' },
  	{ "dir", required_argument, NULL, 'd' },
  	{ "out", 1, 0, 'o' },
  	{ "name", optional_argument, NULL, 'n' },
  	{ "user", required_argument, &lopt, 1 },
  	{ "passwd", required_argument, &lopt, 2 },
  	{ 0, 0, 0, 0 }
  };
  ```

* longindex，如果longindex不为NULL，它将指向一个变量，该变量被设置为longopts相对于long选项的索引。

* 全局变量：
  *  optarg：表示当前选项对应的参数值。 
  *  optind：表示的是下一个将被处理到的参数在argv中的下标值。 
  *  opterr：如果opterr = 0，在getopt、getopt_long、getopt_long_only遇到错误将不会输出错误信息到标准输出流。opterr在非0时，向屏幕输出错误。 
  *  optopt：表示没有被未标识的选项。 

* 返回值：
  *  如果短选项找到，那么将返回短选项对应的字符。 
  *  如果长选项找到，flag为NULL，返回`val`；flag不为空，返回`0 `，flag指向val。
  *  如果一个选项既不在长选项也不在短选项。或者在长字符里面存在二义性的，返回`？`。
  *  如果选项需要参数，忘了添加参数。返回值取决于optstring，如果其第一个字符是`:`，则返回`:`，否则返回`?`。 
  * 如果已经解析了所有命令行选项，那么将返回`-1`。

示例：

```c
//./a.out --out=oo -0 00 -1 01 -2 02  --dir dd --name=Name -nName
#include <stdio.h>	/* for printf */
#include <stdlib.h>	/* for exit */
#include <getopt.h>

void showUsage() {
	printf("Usage: getopt_test [OPTION]\n"
			"\n"
			"  -h, --help\n"
			"  ......"
			"\n");
}
int lopt;
int main(int argc, char** argv) {
	int c;
	int digit_optind = 0;
	while(1) {
		int this_option_optind = optind ? optind : 1;
		int longindex = 0;
		lopt = 0;
		const char *optstring = "hvd:o:n::012";
		static struct option longopts[] = {
			{ "help", no_argument, NULL, 'h' },
			{ "version", no_argument, NULL, 'v' },
			{ "dir", required_argument, NULL, 'd' },
			{ "out", required_argument, NULL, 'o' },
			{ "name", optional_argument, NULL, 'n' },
			{ "user", required_argument, &lopt, 1 },
			{ "passwd", required_argument, &lopt, 2 },
			{ 0, 0, 0, 0 }
		};  
		c = getopt_long(argc, argv, optstring, longopts, &longindex);
		
		if(c == -1) {
			break;
		}   
		switch(c) {
		case '0':
		case '1':
		case '2':
			if (digit_optind != 0 && digit_optind != this_option_optind)
				printf("digits occur in two different argv-elements.\n");
			digit_optind = this_option_optind;
			printf("option %c\n", c); 
			break;
		case '?':
		case 0:{
			switch(lopt) {
			case 1: {
				printf("1: optarg is %s optind  is %d argv[optind - 1] is %s \n", optarg, optind, argv[optind - 1]);
			}break;
			case 2:
				printf("option %s", longopts[longindex].name);
				if (optarg)
					printf(" with arg %s", optarg);
				printf("\n");
			}   
			break;
		}   
		case 'd':
		case 'o':
		case 'n':
			printf("option %c: optarg is %s optind  is %d argv[optind - 1] is %s \n", c, optarg, optind, argv[optind - 1]);
			break;
		case 'v':
			printf("v: no_argument, optarg is %s \n", optarg);
			exit(0);
		case 'h':
			showUsage();
			exit(0);
		default:
			printf("default\n");
			showUsage();
			exit(1);
		}
	}
	for(int i; i<argc; i++)
	{
		printf("argv[%d] is %s\n", i, argv[i]);
	}
	if (optind < argc) {
		printf("non-option ARGV-elements: ");
		while (optind < argc)
			printf("%s ", argv[optind++]);
		printf("\n");
	}
	return 0;
}
```

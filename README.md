* 组件：**这里填写项目简介**

		project
		|
		|-gradle   编译工具所需要的文件包
		|
		|-projects 存放源码工程
		|
		|-targets  存放各平台源码编译脚本
		|
		|-output   编译生成的动态库和体验demo
		|
		|-tools    一些脚本工具

* 用法：
	- 将跨平台源码工程放在 projects/projects 下
	- 配置java安装环境
	- 拷贝 template.properties 为 local.properties 并填写相关的配置
	- 执行 ./gradlew tasks 查看编写好的可编译的多平台
	
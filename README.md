simpleUpload
============

　　SimpleUpload是借助JS和flash(AS3)写的上传组件，用于解决浏览器不支持多文件上传（现在HTML5已经逐渐支持）和客户端文件压缩的功能。

　　内部flash的定位及上传进度条的控制是基于JQuery的。

　　可使用Uglify进行压缩，参考[compress.js](https://github.com/tonny-zhang/nodeJS/tree/master/uglifyJS_compress)
## 如何用？

1.引入脚本及样式

```
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
<script type="text/javascript" src="../src/upload.js"></script>
<link rel="stylesheet" type="text/css" href="../src/css/reset.css"></link>
<link rel="stylesheet" type="text/css" href="../src/css/upload.css"></link>
```
2.初始化

```
	var uploadObj = new Upload();
	uploadObj
	.on('mouseEnter',function(){
		btn.css('background-color','red');
	})
	.on('mouseLeave',function(){
		btn.css('background-color','');
	})
	.on('mouseDown',function(){
		btn.css('background-color','green');
	})
	.on('mouseUp',function(){
		btn.css('background-color','black');
	})
	.on('error',function(err){//错误统一调用,包括配置错误，如：没有配置url（造成无法上传数据）
		console.log('自定义error事件：',err);
	})
	.on('uploadCompleteAll',function(files){
		console.log('上传的图片为：',files,files.length);
	})
	.on({
		'getFiles': function(flashName,files){
			
		},
		'toMaxFiles': function(){
			
		}
	})
	.config('swf', '../flash/index.swf')
	.config('uploadUrl','../extra/upload.html')
	.config('btn',btn)
	.config({
		'thumbnailQuality': 100,
		'thumbnailWidth': 100,
		'thumbnailHeight': 100
	})
	.appendTo($('body'))//缓存容器,调用resetPos
```

## 有哪些API?

**约定：斜体的API及属性不提倡使用**
* API
	* config (配置参数)

		```
		uploadObj 
		.config('swf', '../flash/index.swf')
		.config('uploadUrl','../extra/upload.html')
		.config('btn',btn)
		.config({
			'thumbnailQuality': 100,
			'thumbnailWidth': 100,
			'thumbnailHeight': 100
		})
		```
	* on (定制事件)

		```
		uploadObj
		.on('mouseEnter',function(){
			btn.css('background-color','red');
		})
		.on('mouseLeave',function(){
			btn.css('background-color','');
		})
		.on('mouseDown',function(){
			btn.css('background-color','green');
		})
		.on('mouseUp',function(){
			btn.css('background-color','black');
		})
		.on('error',function(err){//错误统一调用,包括配置错误，如：没有配置url（造成无法上传数据）
			console.log('自定义error事件：',err);
		})
		.on('uploadCompleteAll',function(files){
			console.log('上传的图片为：',files,files.length);
		})
		.on({
			'getFiles': function(flashName,files){
				
			},
			'toMaxFiles': function(){
				
			}
		})
		```
	* off (关闭事件)
	* emit (触发事件)

		emit(eventName,eventData[,eventData...])

		```
		uploadObj
		.emit('getFiles',[{"name": "072136xIK.jpg","index":0},{"name": "测试.jpg","index":1}])
		.emit('uploadProcess','1',0.45);
		```
	* appentTo (将flash添加到指定容器)

		强制使用此方法，若不使用或参数不正确，内部会触发error事件
	* resetPos

	　　当初始化时按钮的形态（位置、尺寸）发生变化时，可以用此方法调整flash的位置和尺寸。要求必须配置btn和调用appendTo方法，融内部会触发error事件。
		
		uploadObj.resetPos();
	* *initEvent (初始化内部事件)*

		**!!不提倡使用**
		这里定义了默认的进度条事件，若不想使用可在使用前将基设置成空函数
* 属性
	* uploadedFiles (上传完的图片信息，initEvent定义的事件里初始化)
	* name　(当前Upload实例的名称)

		为满足同时使用多个上传组件，数据及事件缓存都是基于此属性
	* setting (当前Upload实例的配置)
	* *processTmpl (进度条JQuery对象)*

		**为内部操作方便，缓存的数据,也是基于initEvent**
	* *processFiles (进度条每个文件List的JQuery对象)*

		**为内部操作方便，缓存的数据,也是基于initEvent**
	* container (appendTo传入的flash的容器)
	* *flashObj (flash的JQuery对象)*


##有问题和Bug怎么办？
　　有任何问题和Bug都欢迎到[New Issue](https://github.com/tonny-zhang/simpleUpload/issues/new)进行交流。
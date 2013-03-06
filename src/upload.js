(function(global,variableName){
	var isMicrosoft = ~navigator.appName.indexOf("Microsoft");
	var debug = /debug/.test(location.search);//调试模式
	variableName = variableName || 'Upload';
	var now = new Date().getTime();
	var flashCallbackName = [variableName,now,'cb'].join('_');

	var Util = {};
	Util.slice = function(arr,num){
		return [].slice.call(arr,num||0);
	}
	//用null填充属性
	Util.initNull = function(obj,properties){
		for(var i = properties.length;i>0;i--){
			obj[properties[i-1]] = null;
		}
		return obj;
	}
	Util.isEmpty = function(ele,trueFn,falseFn){
		var fn = (ele?falseFn:trueFn);
		fn && fn();
	}
	Util.getFlashHtml = function(id,width,height,setting){
		var swf = setting.swf+(setting.swfVersion||'');
		var flashParam = $.param(Util.getFlashParam(id,setting));
		/*FF中浏览器只认识embed标记，所以如果你用getElementById获 flash的时候，
		需要给embed做ID标记，而IE是认识object标记的 ，所以你需要在object上的
		ID做上你的标记*/
		var flashHtml = 
			'<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=7,0,0,0" id="'+id+'">'+
			'<param name="allowScriptAccess" value="sameDomain" />'+
			'<param name="movie" value="'+swf+'" />'+
			'<param name="quality" value="high" />'+
			'<param name="bgcolor" value="#ffffff" />'+
			'<param name="wmode" value="transparent">'+
			'<param name="flashvars" value="'+flashParam+'">'+
			'<embed src="'+swf+'" name="'+id+'" quality="high" bgcolor="#ffffff" name="'+id+'" swLiveConnect="true" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" wmode="transparent" flashvars="'+flashParam+'"/> '+
		  '</object>';
		return flashHtml;
	}
	//得到初始化flash时的参数	
	Util.getFlashParam = function(flashName,settings){
		var pArr = ['minWidth','minHeight','thumbnailWidth','thumbnailHeight','thumbnailQuality',
			'fileType','allowFileSize','allowFileSize','noCompressUnderSize',
			'allowFileNum','fileName','uploadUrl'];
		var flashPram = {'movieName': flashName,'cb': flashCallbackName};
		for(var i=pArr.length-1;i>0;i--){
			var key = pArr[i],val;
			if(key in settings && (val = settings[key])){
				flashPram[key] = val;
			}
		}
		return flashPram;
	}
	/*url参数加debug即可调试*/
	Util.log = (function(){
		if(typeof console != 'undefined' && debug){
			return function(){
				console.log.apply(console,Util.slice(arguments));
			}
		}else{
			return function(){};
		}
	})();
	//上传进度模板
	Util.getUploadTmpl = function(name,fileList){
		var str = '<ul class="upload_progress" id="'+name+'_progress">';
		for(var i = 0,j=fileList.length;i<j;i++){
			var file = fileList[i],index=file.index,fName = file.name;
			str += 		'<li class="upload_file">'+
							'<span class="upload_filename" title="'+fName+'">'+fName+'</span>'+
							'<span class="upload_close" data-name="'+name+'" data-index="'+index+'">X</span>'+
							'<span class="upload_status">等待..</span>'+
							'<span class="upload_progressbar"></span>'+
						'</li>';
						}
			str +=		'<li>'+
							'<input class="upload_cancel_btn" type="button" value="取消所有上传"/>'+
						'</li>'+
					 '</ul>';
		return $(str);
	}
	var Event = function(type,msg){
		this.msg = msg;
		this.type = type;
	}
	Event.TYPE_CONFIG = '01';//配置错误代码
	var defaultSettings = Util.initNull({
		'swf': '../flash/upload.swf'
		,'checkFile' : function(imgInfo){//检测上传完成后的信息是否是正确的图片信息(每个上传后台输出内容不可能一致)
			return imgInfo;
		}
	},[	 'btn'				//要显示的按钮
		,'uploadUrl'		//上传URL
		,'swfVersion'		//flash的版本号
		,'fileType'			//文件类型,flash里默认为"*.jpg;*.gif;*.png"
		,'allowFileSize'	//允许上传的文件大小,flash里默认为6m
		,'noCompressUnderSize' //小于这个大小时不压缩,flash里默认为 300k
		,'allowFileNum' 	//允许上传的最大数量,flash里默认为 6
		,'fileName'			//上传文件的字段名,flash里默认为 imagefile
		,'minWidth'			//上传图片的最小宽度，不设置或０时不限制
		,'minHeight'		//上传图片的最小高度，不设置或０时不限制
		,'thumbnailWidth'	//上传图片生成的缩略图的宽度，对上传图片宽度有较高要求时进行设置
		,'thumbnailHeight'	//上传图片生成的缩略图的高度，对上传图片宽度有较高要求时进行设置
		,'thumbnailQuality'	//上传图片生成的缩略图的质量，对上传图片宽度有较高要求时进行设置，flash默认为80,[1-100]
	]);
	
	var uploadCache = {length: 0};
	var Upload = function(setting){
		var self = this;
		var flashName = [variableName,now,uploadCache.length++].join('_');
		uploadCache[(self.name = flashName)] = self;
		self.config(setting).initEvent();
		self.uploadedFiles = [];
	}
	var uploadProp = Upload.prototype;
	/*flash会通知的事件及参数：
	Notice:函数内this指向当前操作的Upload对象
	括号里表示参数
	[
	error 		//自定义错误,(error{type,msg})

	//鼠标事件
	,mouseEnter	//鼠标移上,()
	,mouseLeave	//鼠标移出，()
	,mouseDown	//鼠标按下，()
	,mouseUp	//鼠标按起，()

	,toMaxNum	//达到最大上传数量,(remainNum,allowFileNum)
	,toMaxSize	//图片超过允许的大小,([fileNames],allowFileSize)
	,illegalFileType	//上传文件类型不对,([fileNames],fileType)

	,getFiles		//得到文件信息时触发，([files])
	,startUpload	//某个文件开始上传时触发，(fileName)
	,uploadProcess	//文件上传过程触发，(fileName,percent{0-1})
	,uploadError	//上传文件时出现错误时触发，(fileName,type,msg)
	,uploadComplete //上传完成时触发，(fileName,fileInfo)/()
	,uploadCompleteAll//全部上传完成时触发，()
	,beforeCompress	//压缩处理之前触发，(fileName,fileInfo{width,height,size})
	,afterCompress	//压缩处理后触发，(fileName,fileInfo{width,height,size}
	,cancelSuccess	//文件取消时触发，(fileName)/()
	]*/
	uploadProp.initEvent = function(){
		this.on({
			toMaxSize: function(allowFileSize,irregularInfo){//文件太大事件
				alert('最大可上传大小为 '+allowFileSize+' 的文件');
			}
			,toMaxNum: function(remainNum){//达成最大数量事件
				alert('最多可上传'+remainNum+'个文件');
			}
			,illegalFileType: function(allowFileType,irregularInfo){//文件类型不正确
				alert('请选择正确的文件类型');
			}
			,cancel: function(index){
				(isMicrosoft?window:document)[this.name].cancel(index);
			}
			,cancelSuccess: function(fileName){
				var self = this;
				var removeAll = true;
				if(fileName){
					var processFile = self.processFiles[fileName];
					processFile && processFile.remove();
					removeAll = --self.processFiles.length;
				}
				if(removeAll){//reset数据
					delete self.processTmpl.remove();
					delete self.processFiles;
				}
			}
			,startUpload: function(){
				this.uploadedFiles = [];
			}
			,getFiles: function(files){
				var self = this,flashObj = self.flashObj,offset = flashObj.position();
				var processTmpl = self.processTmpl = 
				Util.getUploadTmpl(self.name,files)
				.css({left: offset.left,top: offset.top + flashObj.height()})
				.find('.upload_close').click(function(){
					self.emit('cancel',$(this).data('index'));
				})
				.end()
				.find('.upload_cancel_btn').click(function(){
					self.emit('cancel');
				})
				.end().appendTo(self.container);
				var tempProcessFiles = {length:0};
				processTmpl.find('.upload_file').each(function(i,ele){
					tempProcessFiles[i] = $(ele);
					tempProcessFiles.length++;
				});
				self.processFiles = tempProcessFiles;
			}
			,uploadProcess: function(fileName,percent){
				percent = Number(percent) || 0;
				var self = this;
				var $file = self.processFiles[fileName];
				$file.find('.upload_status').html((percent*100).toFixed(2)+'%');
				$file.find('.upload_progressbar').css('width',function(){
					var $this = $(this),s=$this.data('tW');
					if(!s){
						s = $this.parent().width()-parseFloat($this.css('left'))*2;
						$this.data('tW',s);
					}
					return s*percent;
				});
			}
			,uploadComplete: function(fileName,imgInfo){
				var self = this;
				if(fileName){
					imgInfo = $.parseJSON(imgInfo);
					if(self.setting.checkFile(imgInfo)){
						self.uploadedFiles.push(imgInfo);
						//修复出现异常的上传进度条
						self.emit('uploadProgress',fileName,1);
						self.uploadedFiles[fileName] = imgInfo;
						self.processFile[fileName]
						.find('.upload_status').html('成功')
						.end().find('.upload_progressbar').css('width',function(){
							var $this = $(this);
							return $this.parent().outerWidth()-$($this).css('left');
						})
						.end().find('.upload_close').remove();
					}else{
						self.emit('cancelSuccess').emit('error',imgInfo);//这里最好返回{type:xx,msg:xx}
					}
				}else{//全部上传完成
					self.emit('cancelSuccess');
					var uploadedFiles = self.uploadedFiles;
					if(uploadedFiles && uploadedFiles.length > 0){//上传全部文件有上传成功的，触发uploadCompleteAll事件
						self.emit('uploadCompleteAll',uploadedFiles);
					}
				}
			}
			,error: Util.log
			,uploadError: function(fileName,type,msg){
				this.failedNum++;
				this.emit('error',{type:type,msg:msg});
			}
		});
	}
	/*配置*/
	uploadProp.config = function(setting){
		var extend = $.extend;
		var self = this;
		self.setting || (self.setting = extend(true,{},defaultSettings));
		var args = arguments;
		if(typeof setting == 'string' && args.length == 2){
			var temp_setting = {};
			temp_setting[setting] = args[1];
			setting = temp_setting;
		}
		extend(true,self.setting,setting);
		return self;
	}
	/*定义事件*/
	uploadProp.on = function(eventName,fn){
		var self = this;
		var events = {}
		if(fn){
			events[eventName] = fn;
		}else{
			events = eventName;
		}
		var selfEvent = self.events || (self.events = {});
		for(var i in events){
			(selfEvent[i] || (selfEvent[i] = [])).push(events[i]);
		}
		return self;
	}
	/*关闭事件*/
	uploadProp.off = function(eventName,fn){
		var self = this;
		if(fn){
			var selfEvent = self.events[eventName];
			for(var i = selfEvent.length;i>0;i--){
				if(selfEvent[i-1] == fn){
					selfEvent.splice(i-1,1);
				}
			}
		}else{
			delete self.events[eventName];
		}
		return self;
	}
	/*触发事件*/
	uploadProp.emit = function(eventName/*,args..*/){
		var self = this;
		var selfEvent = self.events[eventName] || [];
		var data = Util.slice(arguments,1);
		var temp_val = [];
		for(var i = 0,j=selfEvent.length;i<j;i++){//保证执行顺序
			var temp = selfEvent[i].apply(self,data);
			temp && temp_val.push(temp);
		}
		if(temp_val.length > 0){			
			self.tempEventReturn = temp_val;//临时存放事件的返回值数据
		}
		return self;
	}
	uploadProp.appendTo = function(ele){
		var self = this,setting = self.setting;
		ele = $(ele);
		if(ele && ele.length){
			if(!setting.uploadUrl){
				_errorConfig.call(self,'uploadUrl');
			}else{
				var flashObj = $(Util.getFlashHtml(self.name,0,0,setting)).css({'position': 'absolute','z-index': 99});
				self.container = $(ele).append((self.flashObj = flashObj)).css('position','relative');
				self.resetPos();
			}
		}else{
			_errorConfig.call(self,'appendTo1');
		}
		return self;
	}
	var _errorConfig = function(msg){
		this.emit('error',new Event(Event.TYPE_CONFIG,msg));
	}
	/*重置flash的位置和尺寸*/
	uploadProp.resetPos = function(){
		var self = this;
		var setting = self.setting;
		var btn = $(setting.btn);
		if(btn && btn.length){
			if(!setting.uploadUrl){
				_errorConfig.call(self,'uploadUrl');
			}else if(!self.container){
				_errorConfig.call(self,'appendTo');
			}else{
				var offset = btn[(~self.container.find(btn).length ? 'position':'offset')]();
				self.flashObj.css(offset).add(self.flashObj.find('embed')).css({
					width: btn.outerWidth(),
					height: btn.outerHeight()
				});
			}			
		}else{
			_errorConfig.call(self,'btn');
		};
		return self;
	}
	global[flashCallbackName] = function(flashName/*,fnName,args*/){
		Util.log.apply(null,Util.slice(arguments));
		var upload = uploadCache[flashName];
		if(upload){
			upload.emit.apply(upload,Util.slice(arguments,1));
			return upload.tempEventReturn;
		}
	}
	global[variableName] = Upload;
	if(debug){			
		//用于测试
		global['Util'] = Util;
		global.uploadCache = uploadCache;
	}
})(this);
package  {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	import flash.events.*;
	
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.net.FileFilter;	
	
	import flash.utils.ByteArray;
	
	import flash.system.Security;
	
	import Debug;
	public class Main extends MovieClip{
		private var _settings = {
			'loadDelay' : 5000,						//加载图片的超时时间
			'minWidth' : 0,							//文件最小宽度	(为0时表示不限制宽度)
			'minHeight' : 0,						//文件最小高度	(为0时表示不限制高度)
			'thumbnailWidth': 0,					//缩略图宽度		(thumbnailWidth和thumbnailHeight同时为0时不压缩尺寸)
			'thumbnailHeight' : 0,					//缩略图高度
			'thumbnailQuality' : 80,				//压缩品质 1~100
			'movieName' : 'upload',					//js传进来的初始化对象名
			'fileType' : '*.jpg;*.jpeg;*.gif;*.png',//默认文件类型
			'allowFileSize' : 6*1024*1024,			//允许上传的最大文件大小,默认6M
			'noCompressUnderSize' : 300*1024,		//当文件大小小于这个值时也不会压缩尺寸，默认300k
			'allowFileNum' : 6,						//本次会话允许上传的最大数量
			'fileName' : 'imagefile',				//上传图片时的字段名
			'uploadUrl' : 'http://git.zk.com/simpleUpload/extra/upload.html',//上传路径
			'extraParam' : null,					//上传
			'cb': 'upload_cb'
		};
		private var _fileFilterArr:Array;		
		private var _fileBrowserMany:FileReferenceList = new FileReferenceList();
		
		/*统计不同状态的文件数*/
		private var _waittingFiles:Array = new Array();
		private var _uploadingFiles:Array = new Array();
		private var _uploadedFiles:Array = new Array();
		private var _cancelingFiles:Array = new Array();//正在取消的文件
		private var _failedFiles:Array = new Array();
		private var _currentFile:FileItem;
		
		private var button:Sprite;
		private var jsCaller:JsCaller;
		private var flashCaller:FlashCaller;
		//用于事件中调用
		private var _self:Main;
		
		public function Main() {
			Security.allowDomain("*");	// Allow uploading to any domain
			Security.allowInsecureDomain("*");	// Allow uploading from HTTP to HTTPS and HTTPS to HTTP
			
			_self = this;
			_self.initSettings(root.loaderInfo.parameters);
			_self._initStage();
			
			_self.jsCaller = new JsCaller(_self._settings.movieName,_self._settings.cb);
			_self.flashCaller = new FlashCaller(_self);
		}
		/*格式化文件大小设置*/
		private function _formatSizeNum(size:String):Number{
			if(size){
				var reg:RegExp = /(\d+)\s*([kmg]?)/;//默认为m  
				var _re = reg.exec(size.toLocaleLowerCase())
				if(_re != null){
					var p:int = 1024;
					switch (_re[2]){
						case '' :
						case 'm' :
							p *= 1024;
							break;
						case 'k' :
							break;
						case 'g' :
							p *= 1024*1024;
							break;
					}
					return Number(_re[1])*p;
				}
			}
			return 0;
		}
		private function getSettings():Object{
			return _self._settings;
		}
		/*初始化配置	*/
		public function initSettings(args:Object){
			args = args||{};
			args.allowFileSize = _self._formatSizeNum(args.allowFileSize);
			args.noCompressUnderSize = _self._formatSizeNum(args.noCompressUnderSize);
			
			var settings = _self.getSettings();
			for(var i in args){
				var val = args[i];
				if(val){
					settings[i] = val;
				}
			}
			//通知初始化参数成功
			//jsCaller.callback(JsCaller.EVENT_INIT_SETTING_SUCCESS);
		}
		/*初始化舞台*/
		private function _initStage(){
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var btn = new Sprite();
			this.button = btn;
			btn.graphics.beginFill(0xFFF,0);
			btn.graphics.drawRect(0,0,1000,1000);
			btn.graphics.endFill();
			btn.useHandCursor = true;
			btn.buttonMode = true;
			btn.mouseChildren = false;

			stage.addChild(btn);
			
			
			/*
			//用于取消调试
			stage.addEventListener(KeyboardEvent.KEY_DOWN,function(){
				trace('---key_down');_self.cancelUpload('');
			});*/
			btn.addEventListener(MouseEvent.CLICK,this._handle_btn_click);
			btn.addEventListener(MouseEvent.MOUSE_OVER,this._handle_btn_enter);
			btn.addEventListener(MouseEvent.MOUSE_OUT,this._handle_btn_leave);
			btn.addEventListener(MouseEvent.MOUSE_DOWN,this._handle_btn_down);
			btn.addEventListener(MouseEvent.MOUSE_UP,this._handle_btn_up);
			
			this._fileBrowserMany.addEventListener(Event.SELECT, this._handle_browser_select);
			this._fileBrowserMany.addEventListener(Event.CANCEL,  this._handle_browser_cancel);
			
		}
		/*取消上传*/
		public function cancelUpload(fileName:String){
			var _waitingFiles = _self._waittingFiles,
				_cancelingFiles = _self._cancelingFiles,
				isCancelAll = !fileName && fileName != '0';
			
			if(isCancelAll || (_self._currentFile && _self._currentFile.getFileName() == fileName)){
				_cancelingFiles.push(_self._currentFile);
			}
			for(var i = 0,j=_waitingFiles.length;i<j;i++){
				var _f = _waitingFiles[i];
				if(isCancelAll || fileName == _f.getFileName()){
					_cancelingFiles = _cancelingFiles.concat(_waitingFiles.splice(i--,1));
				}
			}
			_self._cancelingFiles = _cancelingFiles;//councat那里把指针指向了一个新的数组
			if(_cancelingFiles.length > 0){
				for(i = 0,j = _cancelingFiles.length;i<j;i++){
					var cancelFile = _cancelingFiles[i];
					cancelFile.addEventListener(UploadEvent.UPLOAD_CANCEL_COMPLETE,_self._hancel_cancel_complate);
					cancelFile.cancelUpload();
				}
			}else{
				_self._hancel_cancel_complate(new UploadEvent(UploadEvent.UPLOAD_CANCEL_COMPLETE,null));
			}
		}
		/****************  工具方法  ***************************/
		
		/*得到文件的过滤类型*/
		private function _getFileFilter():Array{
			if(_self._fileFilterArr == null){
				var fileType = _self._settings.fileType;
				var fileTypeArr:Array = fileType.split(';');
				_self._fileFilterArr = new Array();
				_self._fileFilterArr.push(new FileFilter(fileType, fileType));
				if(fileTypeArr.length > 1){
					for(var i=0,j=fileTypeArr.length;i<j;i++){
						var type = fileTypeArr[i];
						_self._fileFilterArr.push(new FileFilter(type, type));
					}
				}
			}
			
			return _self._fileFilterArr;
		}
		/*************　事件处理  ****************/
		private function _hancel_cancel_complate(e:UploadEvent){
			var fileName = e.fileName || null;
			_self.jsCaller.callback(JsCaller.EVENT_CANCEL_SUCCESS,fileName);//通知js取消成功
			
			var cancelingFileLen = _self._cancelingFiles.length;
			if(cancelingFileLen > 0){
				for(var i = 0;i<cancelingFileLen;i++){
					if(_self._cancelingFiles[i].getFileName() == fileName){
						_self._cancelingFiles.splice(i,1);
						break;
					}
				}
			}
			if(!fileName || _self._cancelingFiles.length == 0){
				//当剩余文件都取消时通知全部上传完成
				if(_self._waittingFiles.length == 0){
					_self.jsCaller.callback(JsCaller.EVENT_UPLOAD_COMPLETE);
				}
			}
			
		}
		/*点击事件*/
		private function _handle_btn_click(e:MouseEvent){
			if(_self._waittingFiles.length == 0){
				_self._fileBrowserMany.browse(_self._getFileFilter());
			}
		}
		/*鼠标移上事件*/
		private function _handle_btn_enter(e:MouseEvent){
			_self.jsCaller.callback(JsCaller.EVENT_MOUSE_ENTER);
		}
		/*鼠标移出事件*/
		private function _handle_btn_leave(e:MouseEvent){
			_self.jsCaller.callback(JsCaller.EVENT_MOUSE_LEAVE);
		}
		/*鼠标按下事件*/
		private function _handle_btn_down(e:MouseEvent){
			_self.jsCaller.callback(JsCaller.EVENT_MOUSE_DOWN);
		}
		/*鼠标按起事件*/
		private function _handle_btn_up(e:MouseEvent){
			_self.jsCaller.callback(JsCaller.EVENT_MOUSE_UP);
		}
		
		/*文件选择事件*/
		private function _handle_browser_select(e:Event){
			var file_reference_list = _self._fileBrowserMany.fileList;
			var _settings = _self._settings;
			var remainNum = _settings.allowFileNum - _self._uploadedFiles.length - _self._uploadingFiles.length;
			//超过最大数量
			if(file_reference_list.length > remainNum){
				//调用toMaxNum事件
				_self.jsCaller.callback(JsCaller.EVENT_TO_MAX_NUM,remainNum,_settings.allowFileNum);
				return;
			}
			//有大文件
			var a_size = _settings.allowFileSize;
			var maxSizeFileArr = new Array();
			var noAllowFileArr = new Array();
			var jsFiles = new Array();
			
			var fileType = _settings.fileType;
			
			for(var i=0,j=file_reference_list.length;i<j;i++){
				var file = file_reference_list[i];
				var _fType = file.type;
				var _fName = file.name;
				if(_fType == null){
					_fType = _fName.substring(_fName.lastIndexOf('.'));//兼容mac
				}
				if(!_fType || fileType.indexOf(_fType.toLowerCase()) < 0){
					noAllowFileArr.push(_fName);
				}else if(file.size > a_size){
					maxSizeFileArr.push(_fName);
				}else{
					//_self.jsCaller.log(file.type,fileType.indexOf(file.type));
					_self._waittingFiles.push(new FileItem(i,file,_settings));
					jsFiles.push({'index':i,'name':_fName,'size':file.size});
				}
			}
			var isHaveIllegalError = false;//记录是否有不合法的文件，防止二次点击不出选择框
			if(noAllowFileArr.length > 0){
				_self.jsCaller.callback(JsCaller.EVENT_ILLEGAL_FILE_TYPE,noAllowFileArr,_settings.fileType);
				isHaveIllegalError = true;
			}else if(maxSizeFileArr.length > 0){
				_self.jsCaller.callback(JsCaller.EVENT_TO_MAX_SIZE,maxSizeFileArr,_settings['_allowFileSize']);
				isHaveIllegalError = true;
			}
			if(isHaveIllegalError){//当有不合法文件时把等待文件列表清空
				_self._waittingFiles.splice(0,_self._waittingFiles.length);
			}else{
				jsCaller.callback(JsCaller.EVENT_GET_FILES,jsFiles);//通知js用户选择的文件信息
				_self._nextUpload();
			}
		}
		/*取消文件事件*/
		private function _handle_browser_cancel(e:Event){
			Debug.log('_handle_browser_cancel');
		}
		private function _nextUpload(){
			if(_self._waittingFiles.length==0){
				_self.jsCaller.callback(JsCaller.EVENT_UPLOAD_COMPLETE);
			}else{
				_self._currentFile = _self._waittingFiles.shift();
				_self._currentFile.addEventListener(UploadEvent.UPLOAD_COMPLETE,_self._handle_upload_complete);
				_self._currentFile.addEventListener(UploadEvent.UPLOAD_ERROR,_self._handle_upload_error);
				_self._currentFile.startDeal();
			}
		}
		private function _remove_upload_event(t:Object){
			t.removeEventListener(UploadEvent.UPLOAD_COMPLETE,_self._handle_upload_complete);
			t.removeEventListener(UploadEvent.UPLOAD_ERROR,_self._handle_upload_error);
		}
		/*单个文件上传完成*/
		private function _handle_upload_complete(e:UploadEvent){
			_self._uploadedFiles.push(e.target);
			_self._remove_upload_event(e.target);
			_self.jsCaller.callback(JsCaller.EVENT_UPLOAD_COMPLETE,e.fileName,e.msg);
			_self._nextUpload();
		}
		/*单个文件处理或上传出现错误*/
		private function _handle_upload_error(e:UploadEvent){//已经在FileItem里通知JS
			_self._remove_upload_event(e.target);
			_self._nextUpload();
		}
		
	}
	
}

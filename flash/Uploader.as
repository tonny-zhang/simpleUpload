package  {
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLRequestHeader;
	import flash.events.*;
	
	import flash.utils.Endian;
	
	import flash.utils.ByteArray;
	
	import FileItem;
	import JsCaller;
	public class Uploader{
		private var jsCaller:JsCaller;
		private var eventBindObj:Object;//事件绑定的对象
		private var fileItem:FileItem;
		private var _this:Uploader;
		
		public function Uploader(fileItem:FileItem,fileData:ByteArray,isCompressed:Boolean=true) {
			_this = this;
			_this.fileItem = fileItem;
			jsCaller = fileItem.jsCaller;
			var request:URLRequest = new URLRequest(fileItem.settings.uploadUrl);
			if(!isCompressed){
				var file_reference = _this.eventBindObj = fileItem.file_reference;
				//file_reference.addEventListener(Event.COMPLETE, _this._handle_urlloader_complete);
				file_reference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, _this._handle_filereference_upload_complete);
            	file_reference.addEventListener(Event.OPEN, _this._handle_urlloader_open);
           	 	file_reference.addEventListener(ProgressEvent.PROGRESS, _this._handle_urlloader_progress);
           	 	file_reference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _this._handle_urlloader_security_error);
            	file_reference.addEventListener(HTTPStatusEvent.HTTP_STATUS, _this._handle_urlloader_httpstatus);
            	file_reference.addEventListener(IOErrorEvent.IO_ERROR, _this._hand_urlloader_io_error);
				
				file_reference.upload(request,fileItem.settings.fileName);
				return;
			}
			_this._remove_upload_event();
			var _urlLoader = _this.eventBindObj = new URLLoader();
			
			request.method = URLRequestMethod.POST;
			var postData:ByteArray = new ByteArray();
			postData.endian = Endian.BIG_ENDIAN;
			postData = BOUNDARY(postData);
			postData = LINEBREAK(postData);
			
			postData = writeStringToByte(postData,'Content-Disposition: form-data; name="'+_this.fileItem.settings.fileName+'"; filename="'+_this.fileItem.file_reference.name+'"');
			postData = LINEBREAK(postData);
			postData = writeStringToByte(postData,'Content-Type: application/octet-stream');
			postData = LINEBREAK(postData);
			postData = LINEBREAK(postData);
			postData.writeBytes(fileData,0,fileData.length);
			postData = LINEBREAK(postData);
			postData = BOUNDARY(postData);
			postData = DOUBLEDASH(postData);
			
			request.data = postData;
			request.requestHeaders.push(new URLRequestHeader('Content-Type', 'multipart/form-data; boundary=' + getBoundary()));
			
			
           	_urlLoader.addEventListener(Event.COMPLETE, _this._handle_urlloader_complete);
            _urlLoader.addEventListener(Event.OPEN, _this._handle_urlloader_open);
            _urlLoader.addEventListener(ProgressEvent.PROGRESS, _this._handle_urlloader_progress);
            _urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _this._handle_urlloader_security_error);
            _urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, _this._handle_urlloader_httpstatus);
            _urlLoader.addEventListener(IOErrorEvent.IO_ERROR, _this._hand_urlloader_io_error);
			
			try {
                _urlLoader.load(request);
            } catch (error:Error) {
				_remove_upload_event();
				_this.fileItem.errorMsg(State.ERROR_LOAD_FILE,'文件上传时出现错误');
            }
		}
		/*删除上传事件*/
		private function _remove_upload_event(){
			var t = eventBindObj;
			if(t){
				t.removeEventListener(Event.COMPLETE, _this._handle_urlloader_complete);
				t.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, _this._handle_filereference_upload_complete);
           		t.removeEventListener(Event.OPEN, _this._handle_urlloader_open);
           		t.removeEventListener(ProgressEvent.PROGRESS, _this._handle_urlloader_progress);
           		t.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _this._handle_urlloader_security_error);
           		t.removeEventListener(HTTPStatusEvent.HTTP_STATUS, _this._handle_urlloader_httpstatus);
           		t.removeEventListener(IOErrorEvent.IO_ERROR, _this._hand_urlloader_io_error);
			}
		}
		/*没有压缩上传完成*/
		private function _handle_filereference_upload_complete(e:DataEvent){
			_this._remove_upload_event();
			_this.fileItem.completeDeal(e.data);
		}
		/*压缩后上传完成*/
		private function _handle_urlloader_complete(e:Event){
			_this._remove_upload_event();
			_this.fileItem.completeDeal(URLLoader(e.target).data);
		}
		/*准备上传*/
		private function _handle_urlloader_open(e:Event){
			jsCaller.callback(JsCaller.EVENT_UPLOAD_PROCESS,_this.fileItem.file_name,0);
		}
		/*上传过程*/
		private function _handle_urlloader_progress(e:ProgressEvent){
			var numLoaded:Number = e.bytesLoaded < 0 ? 0 : e.bytesLoaded,
				numTotal:Number = e.bytesTotal < 0 ? 0 : e.bytesTotal,
				percent:Number = 0;
			try{
				percent = numLoaded / numTotal;
			}catch(e:Error){
				
			}			
			//jsCaller.call(_this.file_name,numLoaded,numTotal,percent);
			jsCaller.callback(JsCaller.EVENT_UPLOAD_PROCESS,_this.fileItem.file_name,percent);
		}
		/*上传安全出错*/
		private function _handle_urlloader_security_error(e:SecurityErrorEvent){
			_this._remove_upload_event();
			if(!_this._shamUploadInfo(e)){
				_this.fileItem.errorMsg(State.ERROR_UPLOAD_FILE_SECURITY,'上传时出现安全错误');
			}
		}
		/*httpstatus改变*/
		private function _handle_urlloader_httpstatus(e:HTTPStatusEvent){
			
		}
		/*io错误*/
		private function _hand_urlloader_io_error(e:IOErrorEvent){
			_this._remove_upload_event();
			if(!_this._shamUploadInfo(e)){
				_this.fileItem.errorMsg(State.ERROR_UPLOAD_FILE_IO,'上传时出现IO错误');
			}
		}
		/*当出现错误时，可以调用JS里定义的虚假信息进行逻辑处理*/
		private function _shamUploadInfo(e:ErrorEvent){
			var jsReturnValue = jsCaller.callback(JsCaller.EVENT_SHAM_UPLOAD_INFO,e);
			if(jsReturnValue){
				_this.fileItem.completeDeal(jsReturnValue);
			}
			return jsReturnValue
		}
		/********* 上传报头用 start *********/
		private static var _boundary:String;
		private function getBoundary():String
		{
			if (_boundary == null) {
				_boundary = '';
				for (var i:int = 0; i < 0x20; i++ ) {
					_boundary += String.fromCharCode( int( 97 + Math.random() * 25 ) );
				}
			}
			return _boundary;
		}
		private function BOUNDARY(p:ByteArray):ByteArray
		{
			var l:int = getBoundary().length;
			p = DOUBLEDASH(p);
			for (var i:int = 0; i < l; i++ ) {
				p.writeByte( _boundary.charCodeAt( i ) );
			}
			return p;
		}

		private function LINEBREAK(p:ByteArray):ByteArray
		{
			p.writeShort(0x0d0a);
			return p;
		}
		private function DOUBLEDASH(p:ByteArray):ByteArray
		{
			p.writeShort(0x2d2d);
			return p;
		}
		private function writeStringToByte(p:ByteArray,s:String):ByteArray{
			for ( var i = 0; i < s.length; i++ ) {
				p.writeByte( s.charCodeAt(i) );
			}
			return p;
		}
		/********* 上传报头用 end *********/
	}
	
}

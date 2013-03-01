package  {
	import flash.external.ExternalInterface;
	public class FlashCaller {
		private var main:Main;
		public function FlashCaller(main:Main) {
			this.main = main;
			this.registerCallback();
		}
		/*注册全部JS可以调用的方法*/
		private function registerCallback(){
			ExternalInterface.addCallback('cancel',_handle_cancel);
			ExternalInterface.addCallback('initSettings',_handle_init_setting);
		}
		/*取消上传*/
		private function _handle_cancel(fileName:String=null){
			main.cancelUpload(fileName);
		}
		/*初始化参数*/
		private function _handle_init_setting(settings:Object){
			main.initSettings(settings);
		}
	}
}

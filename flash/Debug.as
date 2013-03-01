package  {
	import flash.display.MovieClip;
	
	public class Debug extends MovieClip{
		private static var _this:Debug;
		private var debug:Boolean;
		public function Debug() {
			this.debug = this.stage.loaderInfo.url.split("/")[0] == 'file:';
		}
		public static function log(... arguments):*{
			trace.apply(trace,arguments);
		}
	}
	
}

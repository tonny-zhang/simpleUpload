package  {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	import flash.filters.BlurFilter;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
		
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	public class Compressor extends Sprite{
		public function Compressor() {
			
		}
		public function compress(loader:Loader,thumbnailWidth,thumbnailHeight,thumbnailQuality) {
			try{
				var _toWidth = thumbnailWidth,
					_toHeight = thumbnailHeight;
					
				var _oldWidth = loader.width,
					_oldHeight = loader.height;
				
				var newWidth = _oldWidth,
					newHeight = _oldHeight;
				//不压缩尺寸
				if(_toWidth > 0 && _toHeight > 0){
					if(_oldWidth > _toWidth || _oldHeight > _toHeight){
						var _r_h = _toHeight/_oldHeight,
							_r_w = _toWidth/_oldWidth;
						if(_r_h > _r_w){
							newWidth = _toWidth;
							newHeight = _oldHeight * _r_w;
						}else{
							newWidth = _oldWidth * _r_h;
							newHeight = _toHeight;
						}
					}
				}

				var bmp:BitmapData = Bitmap(loader.content).bitmapData;
				
				var _oldByte = bmp.getPixels(new Rectangle(0,0,_oldWidth,_oldHeight));
				this.emit(UploadEvent.UPLOAD_BEFORE_COMPRESS,{width:_oldWidth,height:_oldHeight,size:_oldByte.length});
				
				if (newWidth < _oldWidth || newHeight < _oldHeight) {
					var blurMultiplier:Number = 1.15; // 1.25;
					var blurXValue:Number = Math.max(1, bmp.width / newWidth) * blurMultiplier;
					var blurYValue:Number = Math.max(1, bmp.height / newHeight) * blurMultiplier;

					var blurFilter:BlurFilter = new BlurFilter(blurXValue, blurYValue, int(BitmapFilterQuality.LOW));
				
					bmp.applyFilter(bmp, new Rectangle(0, 0, bmp.width, bmp.height), new Point(0, 0), blurFilter);
				
					var matrix:Matrix = new Matrix();
					matrix.identity();
					matrix.createBox(newWidth / bmp.width, newHeight / bmp.height);

					var resizedBmp = new BitmapData(newWidth, newHeight, true, 0x000000);
					resizedBmp.draw(bmp, matrix, null, null, null, true);

					bmp.dispose();
					bmp = resizedBmp;
				}
				//_this._state = State.FILE_STATE_COMPRESSING;//正在压缩
				var newByte = new JPGEncoder(thumbnailQuality).encode(bmp);
				bmp.dispose();
				this.emit(UploadEvent.UPLOAD_AFTER_COMPRESS,{width:newWidth,height:newHeight,byte:newByte});
			}catch(e:Error){
				this.emit(UploadEvent.UPLOAD_COMPRESS_ERROR);
			}
		}
		private function emit(eventType:String,msg:Object=null){trace(arguments);
			this.dispatchEvent(new UploadEvent(eventType,null,msg));
		}
	}
	
}

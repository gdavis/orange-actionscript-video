
package com.factorylabs.orange.unit.video
{
	import asunit.asserts.assertFalse;
	import asunit.asserts.assertNotNull;
	import asunit.asserts.assertEquals;
	import asunit.asserts.assertTrue;

	import com.factorylabs.orange.video.FVideo;

	import flash.display.Sprite;

	/**
	 * Generate the test cases for the FVideo class.
 	 *
 	 * <hr />
	 * <p><a target="_top" href="http://github.com/factorylabs/orange-actionscript/MIT-LICENSE.txt">MIT LICENSE</a></p>
	 * <p>Copyright (c) 2004-2010 <a target="_top" href="http://www.factorylabs.com/">Factory Design Labs</a></p>
	 * 
	 * <p>Permission is hereby granted to use, modify, and distribute this file 
	 * in accordance with the terms of the license agreement accompanying it.</p>
 	 *
	 * @author		Grant Davis
	 * @version		1.0.0 :: Mar 4, 2010
	 */
	public class FVideoTests 
	{
		private var _video	:FVideo;
		
		[Before]
		public function runBeforeEachTest() :void
		{
			_video = new FVideo();
		}
		
		[After]
		public function runAfterEachTest() :void
		{
			_video.dispose();
			_video = null;
		}
		
		[Test]
		public function constructor() :void
		{
			assertTrue( '_video is FVideo', _video is FVideo );
		}
		
		[Test]
		public function should_init_with_holder() :void
		{
			_video.dispose();
			
			var holder : Sprite = new Sprite();
			_video = new FVideo( holder );
			assertTrue( holder.contains(_video ));
		}
		
		[Test]
		public function should_init_with_object_and_set_properties() :void
		{
			_video.dispose();
			
			var options :Object = { x:10, y:20, width:720, height:540 };
			_video = new FVideo( null, options );
			assertEquals( 10, _video.x );
			assertEquals( 20, _video.y );
			assertEquals( 720, _video.width );
			assertEquals( 540, _video.height );
		}
		
		[Test(expects="Error")]
		public function should_throw_error_on_illegal_init_property() :void
		{
			new FVideo( null, { asdf:"you can't set me!" });
		}
		
		[Test]
		public function should_create_references_to_signals() :void
		{
			assertNotNull( _video.stateSignal );
			assertNotNull( _video.connectSignal );
			assertNotNull( _video.metadataSignal );
			assertNotNull( _video.metadataSignal );
			assertNotNull( _video.playheadUpdateSignal );
			assertNotNull( _video.completeSignal );
			assertNotNull( _video.playingSignal );
			assertNotNull( _video.pauseSignal );
			assertNotNull( _video.stopSignal );
			assertNotNull( _video.seekSignal );
			assertNotNull( _video.bandwidthSignal );
		}
		
		[Test]
		public function should_create_connection_object() :void
		{
			assertNotNull( _video.connection );
		}
		
		[Test]
		public function should_set_and_get_auto_detect_bandwidth() :void
		{
			_video.autoDetectBandwidth = false;
			assertFalse( _video.autoDetectBandwidth );
			_video.autoDetectBandwidth = true;
			assertTrue( _video.autoDetectBandwidth );
		}
		
		[Test]
		public function should_set_and_get_use_fast_start_buffer() :void
		{
			_video.useFastStartBuffer = false;
			assertFalse( _video.useFastStartBuffer );
			_video.useFastStartBuffer = true;
			assertTrue( _video.useFastStartBuffer );
		}
		
		[Test]
		public function should_set_and_get_volume() :void
		{
			_video.volume = .65;
			assertEquals( .65, _video.volume );
		}
		
		[Test]
		public function should_set_and_get_align_mode() :void
		{
			_video.align = FVideo.ALIGN_RIGHT;
			assertEquals( FVideo.ALIGN_RIGHT, _video.align );
		}
		[Test(expects="Error")]
		public function should_throw_error_on_illegal_align_mode() :void
		{
			_video.align = "asdf";
		}
		
		[Test]
		public function should_set_and_get_scale_mode() :void
		{
			_video.scaleMode = FVideo.SCALE_EXACT_FIT;
			assertEquals( FVideo.SCALE_EXACT_FIT, _video.scaleMode );
		}
		
		[Test(expects="Error")]
		public function should_throw_error_on_illegal_scale_mode() :void
		{
			_video.scaleMode = "asdf";
		}
	}
}
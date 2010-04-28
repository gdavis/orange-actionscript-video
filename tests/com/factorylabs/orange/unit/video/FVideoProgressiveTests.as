
package com.factorylabs.orange.unit.video
{
	import asunit.asserts.assertEqualsArrays;
	import asunit.asserts.assertTrue;

	import asunit4.async.addAsync;

	import com.factorylabs.orange.video.FVideo;

	import flash.utils.setTimeout;

	/**
	 * Generate the test cases for the FVideo class using progressive video connections.
 	 *
 	 * <hr />
	 * <p><a target="_top" href="http://github.com/factorylabs/orange-actionscript/MIT-LICENSE.txt">MIT LICENSE</a></p>
	 * <p>Copyright (c) 2004-2010 <a target="_top" href="http://www.factorylabs.com/">Factory Design Labs</a></p>
	 * 
	 * <p>Permission is hereby granted to use, modify, and distribute this file 
	 * in accordance with the terms of the license agreement accompanying it.</p>
 	 *
	 * @author		Grant Davis
	 * @version		1.0.0 :: Mar 2, 2010
	 */
	public class FVideoProgressiveTests 
	{
		protected static const HTTP_FILE		:String = "http://172.20.34.110/AdobeBand_640.flv";
		private var _video			:FVideo;
		private var _stateLog		:Array;
		private var _handler		:Function;
		private var _finishHandler	:Function;
		
		[Before]
		public function runBeforeEachTest() :void
		{
			_stateLog = [];
			_video = new FVideo();
		}
		
		[After]
		public function runAfterEachTest() :void
		{
			_video.dispose();
			_video = null;
			_handler = null;
		}
		
		[Test]
		public function constructor() :void
		{
			assertTrue( '_video is FVideo', _video is FVideo );
		}
		
		[Test(async)]
		public function should_advance_through_expected_states_on_play() :void
		{
			_handler = addAsync( handleAndCompareRecordedStates, 10000 );
			_finishHandler = addAsync( finishTest, 11000 );
			_video.playingSignal.add( _handler );
			_video.stateSignal.add( handleAndRecordState );
			playVideo();
		}
		private function handleAndRecordState( $state :String ) :void
		{
			_stateLog.push( $state );
		}
		private function handleAndCompareRecordedStates( $time :Number ) :void
		{
			trace( '[FVideoStateTests].handleAndCompareRecordedStates()' );
			_video.playingSignal.remove( _handler );
			assertEqualsArrays( [ 	FVideo.STATE_CONNECTING, 
									FVideo.STATE_CONNECTED, 
									FVideo.STATE_LOADING, 
									FVideo.STATE_BUFFERING, 
									FVideo.STATE_PLAYING ], _stateLog );
			setTimeout( _finishHandler, 10 );
		}
		
		//-----------------------------------------------------------------
		// Helper methods
		//-----------------------------------------------------------------
		
		private function finishTest() :void
		{
			// this is here to avoid dispose() being called in the same loop that 
			// a signal was dispatched in. Otherwise, we're likely to run into null-reference
			// errors trying to access objects that have been disposed immediately after the test was run.
		}
		
		private function playVideo() :void
		{
			_video.play( HTTP_FILE );
		}
	}
}
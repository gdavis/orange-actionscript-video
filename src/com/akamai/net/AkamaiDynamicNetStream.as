//
// Copyright (c) 2009, the Open Video Player authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without 
// modification, are permitted provided that the following conditions are 
// met:
//
//    * Redistributions of source code must retain the above copyright 
//		notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above 
//		copyright notice, this list of conditions and the following 
//		disclaimer in the documentation and/or other materials provided 
//		with the distribution.
//    * Neither the name of the openvideoplayer.org nor the names of its 
//		contributors may be used to endorse or promote products derived 
//		from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


package com.akamai.net
{
	import flash.net.NetConnection;
	import flash.events.TimerEvent;
	import flash.events.NetStatusEvent;
	import flash.utils.Timer;

	import org.openvideoplayer.net.OvpConnection;
	import org.openvideoplayer.net.OvpDynamicNetStream;
	import org.openvideoplayer.net.dynamicstream.*;
	import org.openvideoplayer.events.OvpEvent;
	import org.openvideoplayer.events.OvpError;
	import com.akamai.net.*;
	
	/**
	 * This class extends OvpDynamicNetStream to provide support  
	 * for live stream subscription and authentication on the Akamai CDN.
	 * 
	 * Note that this class can be used to play single-stream content as well as multi-bitrate content. If you are building a player
	 * that will play content from Akamai, you can invoke this class as your single NetStream instance and then not worry about whether the content is
	 * multi-bitrate or single bitrate. 
	 */
	public class AkamaiDynamicNetStream extends OvpDynamicNetStream 
	{
		protected var _liveStreamAuthParams:String;
		protected var _useFCSubscribe:Boolean;
		protected var _liveStreamTimer:Timer;
		protected var _liveStreamRetryTimer:Timer;
		protected var _liveFCSubscribeTimer:Timer;		
		protected var _liveStreamMasterTimeout:uint;
		protected var _pendingLiveStreamName:String;
		protected var _playingLiveStream:Boolean;
		protected var _successfullySubscribed:Boolean;	
		protected var _AkamaiConnection:AkamaiConnection;
	
		private const LIVE_RETRY_INTERVAL:Number = 10000;
		private const LIVE_ONFCSUBSCRIBE_TIMEOUT:Number = 60000;
		
		/**
		 * Constructor
		 * 
		 * @param connection This object can be either an AkamaiConnection object, an OvpConnection object or a NetConnection object. If an OvpConnection
		 * object is provided, the constructor will use the NetConnection object within it.
		 * <p />
		 * If you are connecting to a live stream on the Akamai network, you must pass in an AkamaiConnection object in order to trigger the correct subscription process.
		 */
		public function AkamaiDynamicNetStream (connection:Object) {
			var _connection:NetConnection = null;
			
			if  (connection is AkamaiConnection) {	
				_AkamaiConnection = AkamaiConnection(connection);
				_connection = _AkamaiConnection.netConnection;
			} else if (connection is OvpConnection) {
				_connection = OvpConnection(connection).netConnection;
			} else {
				_connection = connection as NetConnection;
			}
				
			_liveStreamAuthParams = "";
			_liveStreamMasterTimeout = 3600000;
			
			super(_connection);
			
			if  (connection is AkamaiConnection) {
				
				_useFCSubscribe = AkamaiConnection(connection).subscribeRequiredForLiveStreams;
				isLive = AkamaiConnection(connection).isLive;
				if (isLive) {
					addEventListener(NetStatusEvent.NET_STATUS, listenForUnpublish);
				}	
			}
			
			

		}
		
		/**
		 * Initiates playback of a stream. The argument type passed will dictate whether this class switches or not. If a 
		 * DynamicStreamItem is passed, switching will take place. If a String is passed, conventional non-switching playback will occur and 
		 * the metrics provider instance will be disabled to reduce unnecessary background calculations. 
		 * <p/>
		 * If a String is passed, Akamai specific live stream auth params and the live stream subscription process will be invoked. 
		 * 
		 * @param playObject This object can be either an DynamicStreamItem or a String. If passing a string, you may also pass additional play arguments such
		 * as start, len and reset.
		 * 
		 * @see org.openvideoplayer.net.dynamicstream.DynamicStreamItem
		 */
		public override function play(... arguments):void {
			if (arguments[0] is String && !_isProgressive && arguments && arguments.length) {
				// Add prefix if necessary
				arguments[0] = addPrefix(arguments[0]);
				// Add auth params
				if (_liveStreamAuthParams != "") {
					var name:String = arguments[0];
					arguments[0] = name.indexOf("?") != -1 ? name + "&"+_liveStreamAuthParams : name+"?"+_liveStreamAuthParams;
					isLive = true;
				}
			
				if (_useFCSubscribe && isLive) {
					// We set up the live stream and subscriber 
					_pendingLiveStreamName = arguments[0];
					_playingLiveStream = false;
					_successfullySubscribed = false;
					isLive = true;
					setUpLiveTimers();
					// Listen for internal events - these get dispatched from the OvpConnection class after we call
					// FCSubscribe on our NetConnection instance.
					_nc.addEventListener(OvpEvent.FCSUBSCRIBE, onFCSubscribe);
					_nc.addEventListener(OvpEvent.FCUNSUBSCRIBE, onFCUnsubscribe);
					startLiveStream();
					
				}
			}
			if (arguments[0] is DynamicStreamItem && _useFCSubscribe && _AkamaiConnection.isLive) {
				_dsi = arguments[0] as DynamicStreamItem;
				_isMultibitrate = true;
				isLive = true;
				_nc.addEventListener(OvpEvent.FCSUBSCRIBE, onFCSubscribe);
				_nc.addEventListener(OvpEvent.FCUNSUBSCRIBE, onFCUnsubscribe);
				setUpLiveTimers();
				startLiveStream();
			
			}
			super.play.apply(this, arguments);
		}
		
		/**
		 * The name-value pairs required for invoking stream-level authorization services against
		 * live streams on the Akamai network. Typically these include the "auth" and "aifp" 
		 * parameters. These name-value pairs must be separated by a "&" and should
		 * not commence with a "?", "&" or "/". An example of a valid authParams string
		 * would be:<p />
		 * 
		 * auth=dxaEaxdNbCdQceb3aLd5a34hjkl3mabbydbbx-bfPxsv-b4toa-nmtE&aifp=babufp
		 * 
		 * <p />
		 * These properties must be set before calling the <code>play</code> method,
		 * since per stream authorization is invoked when the file is first played (as opposed
		 * to connection auth params which are invoked when the connection is made).
		 * If the stream-level authorization parameters are rejected by the server, then
		 * <code>NetStatusEvent</code> event with <code>info.code</code> set to "NetStream Failed" will be dispatched. 
		 *
		 * @see AkamaiConnection#connectionAuth
		 * @see #play
		 */
		public function get liveStreamAuthParams():String {
			return _liveStreamAuthParams;
		}
		public function set liveStreamAuthParams(ap:String):void {
			_liveStreamAuthParams = ap;
			isLive = true;
		}
		
		/**
		 * The maximum number of seconds the class should wait before timing out while trying to locate a live stream
		 * on the network. This time begins decrementing the moment a <code>play</code> request is made against a live
		 * stream, or after the class receives an onUnpublish event while still playing a live stream, in which case it
		 * attempts to automatically reconnect. After this master time out has been triggered, the class will issue
		 * an <code>OvpError.STREAM_NOT_FOUND</code> event .
		 * 
		 * @default 3600
		 */
		public function get liveStreamMasterTimeout():Number {
			return _liveStreamMasterTimeout/1000;
		}
		public function set liveStreamMasterTimeout(numOfSeconds:Number):void {
			_liveStreamMasterTimeout = numOfSeconds*1000;
			_liveStreamTimer.delay = _liveStreamMasterTimeout;
			isLive = true;
		}
		
		/**
		 * Initiates the process of unsubscribing from the active live NetStream. This method can only be called if
		 * the class is currently subscribed to a live stream. Since unsubscription is an asynchronous
		 * process, confirmation of a successful unsubscription is delivered via the OvpEvent.UNSUBSCRIBED event. 
		 * 
		 * @return true if previously subscribed, otherwise false.
		 */
		public function unsubscribe():Boolean {
			if (_successfullySubscribed) {
				resetAllLiveTimers();
				_playingLiveStream = false;
				super.play(false);
				_nc.call("FCUnsubscribe", null, _pendingLiveStreamName);
				return true;
			} else {
				return false;
			}
		}
		
		/**
		 * @private
		 */
		protected function addPrefix(filename:String):String {
			var prefix:String;
			var ext:String;
			var loc:int = filename.lastIndexOf(".");
			var requiredPrefix:String;
			var map:Array = new Array();
			map = [ {ext:"mp3", prefix:"mp3"},
					{ext:"mp4", prefix:"mp4"},
					{ext:"m4v", prefix:"mp4"},
					{ext:"f4v", prefix:"mp4"},
					{ext:"3gpp", prefix:"mp4"}, 
					{ext:"mov", prefix:"mp4"} ];
			
			if (loc == -1) {
				// There is no extension, must be an flv
				return filename;
			}
			
			ext = filename.slice(loc+1);
			ext = ext.toLocaleLowerCase();
			
			loc = filename.indexOf(":");
			if (loc == 3) {
				// Prefix is already there
				return filename;
			}
			
			var returnVal:String = filename;
			
			if (loc == -1) {
				// No prefix, add it
				for (var i:uint = 0; i < map.length; i++) {
					if (ext == map[i].ext) {
						returnVal = map[i].prefix + ":" + filename;
						break;
					}
				}
			}
			
			return returnVal;
		}
		
		/**
		 * @private
		 */
		private function startLiveStream():void {
			resetAllLiveTimers();
			_liveStreamTimer.start();
			fcsubscribe();
		}
		
		/**
		 * @private
		 */
		private function fcsubscribe():void {
			
			dispatchEvent(new OvpEvent(OvpEvent.SUBSCRIBE_ATTEMPT));
			if (_isMultibitrate) {
				for (var q:int = 0; q < _dsi.streamCount; q++) {
					_AkamaiConnection.callFCSubscribe(_dsi.getNameAt(q));
				}
			} else {
				_nc.call("FCSubscribe", null, _pendingLiveStreamName);
			}
			
			_liveFCSubscribeTimer.reset();
			_liveFCSubscribeTimer.start();
			_liveStreamRetryTimer.reset();
			_liveStreamRetryTimer.start();
		}
		
		/**
		 * @private
		 */
		private function retrySubscription(e:TimerEvent):void {
			fcsubscribe();
		}
		
		/**
		 * @private
		 */
		private function liveFCSubscribeTimeout(e:TimerEvent):void {
			resetAllLiveTimers();
			dispatchEvent(new OvpEvent(OvpEvent.ERROR, new OvpError(OvpError.NETWORK_FAILED)));
		}
		
		/**
		 * @private
		 */
		private function liveStreamTimeout(e:TimerEvent):void {
			resetAllLiveTimers();
			dispatchEvent(new OvpEvent(OvpEvent.ERROR, new OvpError(OvpError.STREAM_NOT_FOUND)));
		}
		
		/**
		 * @private
		 */
		private function resetAllLiveTimers():void {
			if (_useFCSubscribe)
			{
				_liveStreamTimer.reset();
				_liveStreamRetryTimer.reset();
				_liveFCSubscribeTimer.reset();
			}
			_bufferFailureTimer.reset();
			
		}
		
		/** 
		 * @private
		 */
		private function onFCSubscribe(info:Object):void {
			switch (info.data.code) {
				case "NetStream.Play.Start" :
					resetAllLiveTimers();
					_successfullySubscribed = true;
					dispatchEvent(new OvpEvent(OvpEvent.SUBSCRIBED));
					if (!_isMultibitrate) {
						super.play(_pendingLiveStreamName, -1);
					}
					break;
				case "NetStream.Play.StreamNotFound" :
					_liveStreamRetryTimer.reset();
					_liveStreamRetryTimer.start();
					break;
			} 			
		}
			
		/** 
		 * @private
		 */
		private function onFCUnsubscribe(info:Object):void {
			switch (info.data.code) {
				case "NetStream.Play.Stop":
					_successfullySubscribed = false;
					dispatchEvent(new OvpEvent(OvpEvent.UNSUBSCRIBED)) 
					if (_playingLiveStream) {
						startLiveStream();
					}
				break;
			}
		}
		
		/** 
		 * @private
		 */
		override protected function chooseDefaultStartingIndex():void {
				// Let's measure bandwidth against the server in order to guess our starting point
				_AkamaiConnection.addEventListener(OvpEvent.BANDWIDTH, handleBandwidthResult);
				debug("Measuring bandwidth in order to determine a good starting point");
				_AkamaiConnection.detectBandwidth();
				
		}
		
		/** 
		 * @private
		 */
		private function handleBandwidthResult(e:OvpEvent):void {
			// If the bandwidth has produced a valid value, use it
			if (e.data.bandwidth > 0) {
				for (var i:int = _dsi.streamCount - 1; i >= 0; i--) {
					if (e.data.bandwidth > _dsi.getRateAt(i) ) {
							_streamIndex = i;
							break;
					}
				}
			} else {
				// Sometimes FMS returns a false 0 bandwidth result. In this
				// case, lets start with the first profile above 300kbps. 
				for (var j:int = 0; j < _dsi.streamCount; j++) {
					if (300 < _dsi.getRateAt(j) ) {
						_streamIndex = j;
						break;
					}

				}
				
			}
			makeFirstSwitch();
		}
		
		/** 
		 * @private
		 */
		private function listenForUnpublish(e:NetStatusEvent):void {
			switch (e.info.code) {
				case "NetStream.Play.UnpublishNotify":
					startLiveStream();
				break;
				case "NetStream.Play.PublishNotify":
					resetAllLiveTimers();
				break;
			}
		}
		
		/** 
		 * @private
		 */
		private function setUpLiveTimers(): void {
			// Master live stream timeout
			_liveStreamTimer = new Timer(_liveStreamMasterTimeout, 1);
			_liveStreamTimer.addEventListener(TimerEvent.TIMER_COMPLETE, liveStreamTimeout);
			// Timeout when waiting for a response from FCSubscribe
			_liveFCSubscribeTimer = new Timer(LIVE_ONFCSUBSCRIBE_TIMEOUT,1);
			_liveFCSubscribeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, liveFCSubscribeTimeout);
			// Retry interval when calling fcsubscribe
			_liveStreamRetryTimer = new Timer(LIVE_RETRY_INTERVAL,1);
			_liveStreamRetryTimer.addEventListener(TimerEvent.TIMER_COMPLETE, retrySubscription);
		}
		
	}
	
}
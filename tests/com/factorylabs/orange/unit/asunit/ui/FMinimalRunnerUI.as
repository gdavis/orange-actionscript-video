package com.factorylabs.orange.unit.asunit.ui 
{
	import asunit4.framework.IResult;
	import asunit4.framework.Result;
	import asunit4.runners.BaseRunner;

	import com.factorylabs.orange.unit.asunit.printers.ConsolePrinter;
	import com.factorylabs.orange.unit.asunit.printers.FMinimalPrinter;

	import flash.display.MovieClip;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import flash.system.fscommand;

	/**
	 * Summary.
	 * 
	 * <p>Description.</p>
	 *
	 * <hr />
	 * <p><a target="_top" href="http://github.com/factorylabs/orange-actionscript/MIT-LICENSE.txt">MIT LICENSE</a></p>
	 * <p>Copyright (c) 2004-2010 <a target="_top" href="http://www.factorylabs.com/">Factory Design Labs</a></p>
 	 * 
 	 * <p>Permission is hereby granted to use, modify, and distribute this file 
 	 * in accordance with the terms of the license agreement accompanying it.</p>
	 *
	 * @author		Matthew Kitt
	 * @version		1.0.0 :: Jan 21, 2010
	 */
	public class FMinimalRunnerUI extends MovieClip 
	{		
		protected var printer	:FMinimalPrinter;
		protected var runner	:BaseRunner;
		protected var result	:IResult;
		
		public function FMinimalRunnerUI()
		{
			if (stage) 
			{
				stage.align = StageAlign.TOP_LEFT;
				stage.scaleMode = StageScaleMode.NO_SCALE;
			}
		}
		
		public function run( suite :Class ) :void
		{
			result = new Result();
			
			
			result.addListener( new ConsolePrinter() );
			
			printer = new FMinimalPrinter();
			printer.addEventListener( Event.COMPLETE, onRunnerComplete );
			result.addListener( printer );
			addChild( printer );
			
			runner = new BaseRunner();
			runner.run(suite, result);
		}
		
		protected function onRunnerComplete( $e :Event ) :void
		{
			if( Security.sandboxType == Security.REMOTE )
				ExternalInterface.call( "window.close" );
							if( Security.sandboxType == Security.LOCAL_WITH_NETWORK )
				fscommand('quit');
		}
	}
}

package com.factorylabs.orange.unit.runners 
{
	import com.factorylabs.orange.unit.video.FVideoTestSuite;
	import com.factorylabs.orange.unit.asunit.ui.FMinimalRunnerUI;
	import com.factorylabs.orange.unit.helpers.MockCanvas;

	/**
	 * Runs the test suite associated with the <code>orange.video</code> package.
	 *
	 * <hr />
	 * <p><a target="_top" href="http://github.com/factorylabs/orange-actionscript/MIT-LICENSE.txt">MIT LICENSE</a></p>
	 * <p>Copyright (c) 2004-2010 <a target="_top" href="http://www.factorylabs.com/">Factory Design Labs</a></p>
 	 * 
 	 * <p>Permission is hereby granted to use, modify, and distribute this file 
 	 * in accordance with the terms of the license agreement accompanying it.</p>
	 *
	 * @author		Grant Davis
	 * @version		1.0.0 :: March 2, 2010
	 */
	public class FVideoTestRunner
		extends FMinimalRunnerUI 
	{
		public function FVideoTestRunner() 
		{
			MockCanvas.canvas = stage;	// this is dirty but at least it gives the MockCanvas a reference to the stage for testing visual components.
			run( FVideoTestSuite );
		}
	}
}


package com.factorylabs.orange.unit.helpers 
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;

	/**
	 * MockCanvas is a hook into adding and removing items directly to the <code>Stage</code> via a <code>Canvas</code> 
	 * object and FlexUnit's <code>UIImpersonator</code>.
	 *
	 *<p>This is a workaround for the error that is thrown when a native <code>DisplayObject</code> is added through FlexUnit's <code>UIImpersonator</code>.
	 *
	 * <hr />
	 * <p><a target="_top" href="http://github.com/factorylabs/orange-actionscript/MIT-LICENSE.txt">MIT LICENSE</a></p>
	 * <p>Copyright (c) 2004-2010 <a target="_top" href="http://www.factorylabs.com/">Factory Design Labs</a></p>
 	 * 
 	 * <p>Permission is hereby granted to use, modify, and distribute this file 
 	 * in accordance with the terms of the license agreement accompanying it.</p>
	 *
	 * @author		Matthew Kitt
	 * @version		1.0.0 :: Dec 5, 2009
	 */
	public class MockCanvas
		extends Sprite 
	{
		// this should be set by the runner, dirty dirty dirty... and not in the good "dirty" way.
		public static var canvas :Stage;
		
		public function MockCanvas() 
		{
			super();
			canvas.addChild( this );
		}
		
		public function add( $child :DisplayObject ) :void
		{
			addChild( $child );
		}
		
		public function remove( $child :DisplayObject ) :void
		{
			removeChild( $child );
		}
	}
}

package com.factorylabs.orange.unit.asunit.printers 
{
	import asunit.framework.ITestFailure;

	import asunit4.framework.IResult;
	import asunit4.framework.IRunListener;
	import asunit4.framework.ITestSuccess;
	import asunit4.framework.Method;

	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;

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
	public class ConsolePrinter 
		implements IRunListener 
	{
		protected static const localPathPattern	:RegExp = /([A-Z]:\\[^\/:\*\?<>\|]+\.\w{2,6})|(\\{2}[^\/:\*\?<>\|]+\.\w{2,6})/g;
		protected static const divider			:String = '--------------------\n';
		
		protected var failed	:String = '';
		protected var ignored	:String = '';
		protected var startTime :Number;
		protected var numtests	:uint;
		protected var durations :Array;

		public function ConsolePrinter() 
		{
			durations = [];
		}

		public function onRunStarted() :void
		{
			trace( 'Starting Tests...' );
		}
		
		public function onTestStarted(test :Object) :void
		{
			startTime = getTimer();
			numtests = 0;
		}
		
		public function onTestIgnored(method :Method) :void
		{
			var s :String = '';
			s += getQualifiedClassName( method.scope );
			s+= '.' + method.name;
			s += getIgnoreDescription( method.metadata );
			s += '\n\n';
			ignored += s;
		}
		
		public function onTestFailure(failure :ITestFailure) :void
		{
			var s:String = '';
			var stack:String = '';
			s += getQualifiedClassName(failure.failedTest);
			s += '.' + failure.failedMethod + ' : ';
			
			stack = failure.thrownException.getStackTrace();
			
			stack = stack.replace(localPathPattern, '');
			stack = stack.replace(/AssertionFailedError: /, '');

			s += stack + '\n\n';
			
			failed += s;
			numtests ++;
		}
		
		public function onTestSuccess(success :ITestSuccess) :void
		{
			numtests ++;
		}
		
		public function onTestCompleted(test :Object) :void
		{
			var tt :Number = getTimer() - startTime;
			durations.push( {test: test, time: tt, num: numtests } );
		}
		
		public function onRunCompleted(result :IResult) :void
		{
			var m :String = ( result.wasSuccessful ) ? printSuccessSummary( result ) : printFailureSummary( result ); 
			var s :String = '...Test Complete\n';
			s += divider;
			s += '\n';
			s += printTimeSummary();
			s += '\n';
			s += printIgnoredSummary( result );
			s += divider;
			s += m;
			trace( s );
		}
		
		protected function printSuccessSummary( $result :IResult ) :String
		{
			return 'Test Summary:\nOK (' + $result.runCount + ' test' + ($result.runCount == 1 ? '' : 's' + ')\n') + divider;
		}
		
		protected function printFailureSummary( $result :IResult ) :String
		{
			var s :String = 'FAILURES!!!\n';
			s += 'Tests run: ' + $result.runCount + '\n';
			s += 'Failures: ' + $result.failureCount + '\n';
			s += 'Errors: ' + $result.errorCount + '\n';
			s += divider + '\n';
			s += failed;
			s += divider;
			return s;
		}
		
		protected function printTimeSummary() :String 
		{
			durations.sortOn( ['time', 'num'], [Array.NUMERIC | Array.DESCENDING, Array.NUMERIC | Array.DESCENDING]);
			var s :String = 'Time Summary:\n';

            var len:Number = durations.length;
            for (var i:Number = 0; i < len; i++) 
            {
				var info :Object = durations[ i ];
				s += info[ 'time' ] + ' ms \t';
				s += info[ 'num' ] + ' tests \t ';
				s += getQualifiedClassName(info[ 'test' ] );
				s += '\n';
            }
            return s;
		}
		
		protected function printIgnoredSummary( $result :IResult ) :String
		{
			var s :String = '';
			if( $result.ignoredTestCount > 0 );
				s = 'Ignore Summary:\nIgnoring (' + $result.ignoredTestCount +' tests)\n\n' + ignored;
			return s;
		}
		
		protected function getIgnoreDescription( $list :XMLList ) :String
		{
			var desc :String = '';
			var ignore :XMLList = $list.( @name == 'Ignore' );
			if( ignore )
				desc = '\n  => ' + ignore[ 'arg' ].@value;
			return desc;
		}
	}
}

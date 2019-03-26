/** @flow
 * @format */

import { createElement } from '@wordpress/element';
import jsdom from 'jsdom-jscore';
import jsdomLevel1Core from 'jsdom-jscore/lib/jsdom/level1/core';
import { nativeLoggingHook } from 'react-native-gutenberg-bridge';

// Import for side-effects: Patches for jsdom-jscore, details commented in file.
import './jsdom-patches';

global.wp = {
	element: {
		createElement, // load the element creation function, needed by Gutenberg-web
	},
};

const doc = jsdom.html( '', null, null );

// inject a simple version of the missing createHTMLDocument method that `hpq` depends on
doc.implementation.createHTMLDocument = function( html ) {
	return jsdom.html( html, null, null );
};

// `hpq` depends on `document` be available globally
global.document = doc;

if ( ! global.window.Node ) {
	global.window.Node = jsdomLevel1Core.dom.level1.core.Node;
}

if ( ! global.window.matchMedia ) {
	global.window.matchMedia = () => ( {
		matches: false,
		addListener: () => {},
		removeListener: () => {},
	} );
}

// Leverages existing console polyfill from react-native
global.nativeLoggingHook = nativeLoggingHook;

const previousErrorHandler = global.ErrorUtils.getGlobalHandler();
global.ErrorUtils.setGlobalHandler( ( error, isFatal ) => {
	nativeLoggingHook( error.toString(), isFatal ? 3 : 2 );
	previousErrorHandler( error, isFatal );
} );

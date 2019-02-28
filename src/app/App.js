/** @flow
 * @format */

import React from 'react';

import AppContainer from './AppContainer';
import initialHtml from './initial-html';

type PropsType = {
	initialData: string,
	initialHtmlModeEnabled: boolean,
	initialTitle: string,
};

export default class AppProvider extends React.Component<PropsType> {
	render() {
		const { initialHtmlModeEnabled } = this.props;
		let initialData = this.props.initialData;
		let initialTitle = this.props.initialTitle;
		if ( initialData === undefined ) {
			initialData = initialHtml;
		}
		if ( initialTitle === undefined ) {
			initialTitle = 'Welcome to Gutenberg!';
		}
		return (
			<AppContainer
				initialHtml={ initialData }
				initialHtmlModeEnabled={ initialHtmlModeEnabled }
				initialTitle={ initialTitle } />
		);
	}
}


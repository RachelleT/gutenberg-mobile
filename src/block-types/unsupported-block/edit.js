/**
 * @format
 * @flow
 */

import React from 'react';
import { View, Text } from 'react-native';
import type { BlockType } from '../../store/types';

type PropsType = BlockType & {
	onChange: ( clientId: string, attributes: mixed ) => void,
	onToolbarButtonPressed: ( button: number, clientId: string ) => void,
	onBlockHolderPressed: ( clientId: string ) => void,
};

// Styles
import styles from './style.scss';

export default class UnsupportedBlockEdit extends React.Component<PropsType> {
	render() {
		return (
			<View style={ styles.unsupportedBlock }>
				<Text style={ styles.unsupportedBlockMessage }>Unsupported</Text>
			</View>
		);
	}
}

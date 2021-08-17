
export default waitNBlocks = async n => {
    const sendAsync = promisify(web3.currentProvider.sendAsync);
    await Promise.all(
      [...Array(n).keys()].map(i =>
        sendAsync({
          jsonrpc: '2.0',
          method: 'evm_mine',
          id: i
        })
      )
    );
};
# ETF Vault

A minimal implementation of exchange-traded funds as [ERC-4626](https://eips.ethereum.org/EIPS/eip-4626) vaults.

The ETF's parameters are fixed at deployment for simplification, and has removed some of the interfaces that ERC-4626 has due to incompatibility when depositing multiple assets.

Built for fun, neither serious nor audited.  
No tests included™.

## Build

```sh
forge bulid
```

## License

The code is released under  the `GNU Affero General Public License v3.0` license.

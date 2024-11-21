// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DigitalAssetMarketplace
 * @dev A simple marketplace for minting, listing, and trading NFTs.
 */
contract DigitalAssetMarketplace is ERC721, Ownable {
    struct AssetSale {
        address assetOwner;
        uint256 assetPrice;
        bool isAvailableForSale;
    }

    // Mapping to track asset sales
    mapping(uint256 => AssetSale) private _assetSales;

    // Event declarations
    event AssetMinted(address indexed owner, uint256 indexed assetId);
    event AssetListedForSale(
        address indexed owner,
        uint256 indexed assetId,
        uint256 price
    );
    event AssetPurchased(
        address indexed buyer,
        uint256 indexed assetId,
        uint256 price
    );
    event AssetDelisted(uint256 indexed assetId);

    // Counter for the next asset ID
    uint256 private _nextAssetId;

    // Constructor
    constructor() ERC721("DigitalAssetMarketplace", "DAM") Ownable(msg.sender) {
        // Initialize with the deployer as the owner
    }

    /**
     * @dev Returns the base URI for asset metadata.
     */
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://sapphire-accurate-tortoise-289.mypinata.cloud/ipfs/QmQ18EtpYMnSntmxog5e8dwWsyKMNJanMuWVEcZxWGkDNb";
    }

    // The rest of the contract functions remain unchanged...

    /**
     * @dev Mint a new asset and assign it to the caller.
     */
    function mintAsset() external {
        uint256 assetId = _nextAssetId;
        _nextAssetId++;

        _safeMint(msg.sender, assetId);

        emit AssetMinted(msg.sender, assetId);
    }

    /**
     * @dev List an asset for sale.
     * @param assetId The ID of the asset to list.
     * @param price The sale price for the asset.
     */
    function listAssetForSale(uint256 assetId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        require(
            ownerOf(assetId) == msg.sender,
            "You are not the owner of this asset"
        );
        require(
            !_assetSales[assetId].isAvailableForSale,
            "This asset is already listed for sale"
        );

        _assetSales[assetId] = AssetSale(msg.sender, price, true);

        emit AssetListedForSale(msg.sender, assetId, price);
    }

    /**
     * @dev Buy an asset that is listed for sale.
     * @param assetId The ID of the asset to purchase.
     */
    function buyAsset(uint256 assetId) external payable {
        AssetSale memory sale = _assetSales[assetId];
        require(sale.isAvailableForSale, "This asset is not for sale");
        require(msg.value == sale.assetPrice, "Incorrect value sent");

        address seller = sale.assetOwner;

        // Clear the sale
        delete _assetSales[assetId];

        // Transfer funds to the seller
        (bool success, ) = seller.call{value: msg.value}("");
        require(success, "Transfer to seller failed");

        // Transfer the asset to the buyer
        _transfer(seller, msg.sender, assetId);

        emit AssetPurchased(msg.sender, assetId, sale.assetPrice);
    }

    /**
     * @dev Remove an asset from sale.
     * @param assetId The ID of the asset to delist.
     */
    function delistAsset(uint256 assetId) external {
        require(
            ownerOf(assetId) == msg.sender,
            "You are not the owner of this asset"
        );
        require(
            _assetSales[assetId].isAvailableForSale,
            "This asset is not listed for sale"
        );

        delete _assetSales[assetId];

        emit AssetDelisted(assetId);
    }

    /**
     * @dev Fetch details of an asset sale.
     * @param assetId The ID of the asset.
     * @return AssetSale struct with details of the sale.
     */
    function getAssetSaleDetails(uint256 assetId)
        external
        view
        returns (AssetSale memory)
    {
        return _assetSales[assetId];
    }

    /**
     * @dev Fallback function to reject Ether sent to the contract.
     */
    receive() external payable {
        revert("Direct Ether transfer not allowed");
    }
}

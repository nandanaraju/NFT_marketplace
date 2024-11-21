// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract DigitalArtMarketplace is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    struct Listing {
        address currentOwner;
        uint256 listingPrice;
        bool isAvailableForSale;
    }

    // Mapping to track NFT listings
    mapping(uint256 => Listing) public nftListings;

    // Event declarations
    event ArtTokenCreated(address indexed creator, uint256 indexed tokenId);
    event ArtTokenListed(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 price
    );
    event ArtTokenPurchased(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    uint256 public tokenCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("DigitalArtMarketplace", "DAM");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://my-custom-art-metadata.com/api/";
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev Create a new NFT and assign it to the caller.
     */
    function createArtToken() public {
        uint256 tokenId = tokenCounter;
        tokenCounter++;

        _safeMint(msg.sender, tokenId);

        emit ArtTokenCreated(msg.sender, tokenId);
    }

    /**
     * @dev List an NFT for sale.
     * @param tokenId The ID of the NFT to list.
     * @param price The sale price for the NFT.
     */
    function listArtToken(uint256 tokenId, uint256 price) public {
        require(
            nftListings[tokenId].isAvailableForSale == false,
            "This art token is already listed for sale"
        );
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this art token"
        );
        require(price > 0, "Listing price must be greater than zero");

        nftListings[tokenId] = Listing(msg.sender, price, true);

        emit ArtTokenListed(msg.sender, tokenId, price);
    }

    /**
     * @dev Purchase an NFT that is listed for sale.
     * @param tokenId The ID of the NFT to purchase.
     */
    function purchaseArtToken(uint256 tokenId) public payable {
        Listing memory listing = nftListings[tokenId];
        require(listing.isAvailableForSale, "This art token is not for sale");
        require(msg.value == listing.listingPrice, "Incorrect payment amount");

        address seller = listing.currentOwner;

        // Remove the listing
        delete nftListings[tokenId];

        // Transfer funds to the seller
        (bool success, ) = seller.call{value: msg.value}("");
        require(success, "Payment transfer failed");

        // Transfer the art token to the buyer
        _transfer(seller, msg.sender, tokenId);

        emit ArtTokenPurchased(msg.sender, tokenId, listing.listingPrice);
    }

    /**
     * @dev Remove an NFT from the marketplace.
     * @param tokenId The ID of the NFT to remove.
     */
    function removeArtTokenFromSale(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this art token"
        );
        require(
            nftListings[tokenId].isAvailableForSale,
            "This art token is not currently listed"
        );

        delete nftListings[tokenId];
    }

    /**
     * @dev Fetch details of an NFT listing.
     * @param tokenId The ID of the NFT.
     */
    function getListingDetails(
        uint256 tokenId
    ) public view returns (Listing memory) {
        return nftListings[tokenId];
    }

    /**
     * @dev Fallback function to reject Ether transfers.
     */
    receive() external payable {
        revert("Direct payments not accepted");
    }
}

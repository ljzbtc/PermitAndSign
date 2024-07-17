// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/// @title NFT Market
/// @author liujingze
/// @dev This contract is a simple NFT market contract

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NftMarket {


    error NftMarketplace_NotApprovedForMarketplace();
    error NftMarketplace_NotListed(address nftAddress, uint256 tokenId);
    error NftMarketplace_NotEnoughFunds();
    event NftMarketplace_Listed(
        address indexed token_address,
        uint256 indexed tokenId,
        uint256 sale_price
    );
    event NftMarketplace_Bought(
        address indexed token_address,
        uint256 indexed tokenId,
        address indexed buyer
    );
    // The address of the ERC20 token used for trading
    address public immutable IEC20_TOKEN_ADDRESS;
    address public immutable NFT_OWNER;
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }
    struct Nft_witheList {
        address wallet;
    }
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant Nft_witheList_TYPEHASH = keccak256(
        "Nft_witheList(address wallet)"
    );


    // The list of NFTs on the market
    mapping(address => mapping(uint256 => uint256)) public nftList;


    constructor(address _IEC20_TOKEN, address _NFT_OWNER) {
        IEC20_TOKEN_ADDRESS = _IEC20_TOKEN;
        NFT_OWNER =_NFT_OWNER ;
       
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256("NftMarket"),
                    keccak256("1"),
                    "1",
                    address(this)
                )
            );
    }

    function listItem(
        address token_address,
        uint256 tokenId,
        uint sale_price
    ) public {
        IERC721 nft = IERC721(token_address);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace_NotApprovedForMarketplace();
        }
        nftList[token_address][tokenId] = sale_price;
        emit NftMarketplace_Listed(token_address, tokenId, sale_price);
    }
    
    function _buynft(
        address token_address,
        uint256 tokenId,
        uint buy_token_amount
    ) internal {
        if (nftList[token_address][tokenId] <= 0) {
            revert NftMarketplace_NotListed(token_address, tokenId);
        }

        if (buy_token_amount < nftList[token_address][tokenId]) {
            revert NftMarketplace_NotEnoughFunds();
        }

        IERC20(IEC20_TOKEN_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            nftList[token_address][tokenId]
        );
        IERC721 nft = IERC721(token_address);
        nft.safeTransferFrom(nft.ownerOf(tokenId), msg.sender, tokenId);
        emit NftMarketplace_Bought(token_address, tokenId, msg.sender);
    }
    function hashStruct(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(
        abi.encode(
        EIP712DOMAIN_TYPEHASH,
        keccak256(bytes(eip712Domain.name)),
        keccak256(bytes(eip712Domain.version)),
        eip712Domain.chainId,
        eip712Domain.verifyingContract
)
);
    }
    //keccak256("Nft(address wallet)")
    function verifyBuy(address wallet, uint8 v, bytes32 r, bytes32 s,address token_address,uint256 tokenId,uint256 buy_token_amount) public {
    // Note: we need to use `encodePacked` here instead of `encode`.
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(abi.encode(Nft_witheList_TYPEHASH, wallet))));
    require(ecrecover(digest, v, r, s)==NFT_OWNER, "not whitelisted");

    _buynft(token_address, tokenId, buy_token_amount);

}

}

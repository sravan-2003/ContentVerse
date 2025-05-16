// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContentOwnership {
    struct Content {
        address owner;
        string title;
        string description;
        uint256 timestamp;
        bool isForSale;
        uint256 price;
    }
    
    // Mapping from content hash to content info
    mapping(string => Content) private contentRegistry;
    
    // Mapping from owner to their content hashes
    mapping(address => string[]) private ownerContent;
    
    // Events
    event ContentRegistered(string contentHash, address owner, string title);
    event ContentListedForSale(string contentHash, uint256 price);
    event ContentSold(string contentHash, address from, address to, uint256 price);
    
    /**
     * @dev Register new content ownership
     * @param contentHash IPFS hash of the content
     * @param title Title of the content
     * @param description Description of the content
     */
    function registerContent(string memory contentHash, string memory title, string memory description) public {
        require(contentRegistry[contentHash].owner == address(0), "Content already registered");
        
        contentRegistry[contentHash] = Content({
            owner: msg.sender,
            title: title,
            description: description,
            timestamp: block.timestamp,
            isForSale: false,
            price: 0
        });
        
        ownerContent[msg.sender].push(contentHash);
        
        emit ContentRegistered(contentHash, msg.sender, title);
    }
    
    /**
     * @dev Get content information
     * @param contentHash IPFS hash of the content
     * @return owner Address of the content owner
     * @return title Title of the content
     * @return description Description of the content
     * @return timestamp Time when content was registered
     */
    function getContentInfo(string memory contentHash) public view returns (
        address owner,
        string memory title,
        string memory description,
        uint256 timestamp
    ) {
        Content memory content = contentRegistry[contentHash];
        return (content.owner, content.title, content.description, content.timestamp);
    }
    
    /**
     * @dev Get all content hashes owned by an address
     * @param owner Address of the content owner
     * @return Array of content hashes
     */
    function getContentsByOwner(address owner) public view returns (string[] memory) {
        return ownerContent[owner];
    }
    
    /**
     * @dev List content for sale
     * @param contentHash IPFS hash of the content
     * @param price Price in wei
     */
    function listContentForSale(string memory contentHash, uint256 price) public {
        require(contentRegistry[contentHash].owner == msg.sender, "Only owner can list content for sale");
        require(price > 0, "Price must be greater than zero");
        
        contentRegistry[contentHash].isForSale = true;
        contentRegistry[contentHash].price = price;
        
        emit ContentListedForSale(contentHash, price);
    }
    
    /**
     * @dev Buy content
     * @param contentHash IPFS hash of the content
     */
    function buyContent(string memory contentHash) public payable {
        Content storage content = contentRegistry[contentHash];
        
        require(content.owner != address(0), "Content does not exist");
        require(content.isForSale, "Content is not for sale");
        require(msg.value >= content.price, "Insufficient payment");
        require(content.owner != msg.sender, "Owner cannot buy their own content");
        
        address previousOwner = content.owner;
        uint256 price = content.price;
        
        // Update content ownership
        content.owner = msg.sender;
        content.isForSale = false;
        content.price = 0;
        
        // Update owner content mappings
        // Remove from previous owner's list
        removeContentFromOwner(previousOwner, contentHash);
        
        // Add to new owner's list
        ownerContent[msg.sender].push(contentHash);
        
        // Transfer payment to previous owner
        payable(previousOwner).transfer(msg.value);
        
        emit ContentSold(contentHash, previousOwner, msg.sender, price);
    }
    
    /**
     * @dev Helper function to remove content from owner's list
     */
    function removeContentFromOwner(address owner, string memory contentHash) private {
        string[] storage contents = ownerContent[owner];
        for (uint i = 0; i < contents.length; i++) {
            if (keccak256(bytes(contents[i])) == keccak256(bytes(contentHash))) {
                // Move the last element to the position to delete
                contents[i] = contents[contents.length - 1];
                // Remove the last element
                contents.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Check if content is for sale and get price
     * @param contentHash IPFS hash of the content
     * @return isForSale Whether the content is for sale
     * @return price Price of the content in wei
     */
    function getContentSaleInfo(string memory contentHash) public view returns (bool isForSale, uint256 price) {
        Content memory content = contentRegistry[contentHash];
        return (content.isForSale, content.price);
    }
}
//Smart contract that handles all behavior of exchange
//Deposit & Withdraw Funds 
//Manage Orders - make or cancel orders
//Fill Orders/Do Trades - Charge fees
pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";



//import token
import "./Token.sol";



contract Exchange {
	using SafeMath for uint;


	//State variables
	address public feeAccount; //account that receives exchange fees
	uint256 public feePercent; //Fee Percentage
	address constant ETHER = address(0); //store Ether in tokens mapping with a blank address
	mapping(address => mapping(address => uint256)) public tokens;
	mapping(uint256 => _Order) public orders; //Store Orders
	mapping(uint256 => bool) public orderCancelled; //mapping to store cancelled orders
	uint256 public orderCount; //counterCache to keep count of orders 
	mapping(uint256 => bool) public orderFilled; //mapping to store fulfilled orders


	//Events
	event Deposit(address token, address user, uint256 amount, uint256 balance);
	event Withdraw(address token, address user, uint amount, uint balance);
	event Order(
		uint256 id,
		address user,
		address tokenGet,
		uint256 amountGet,
		address tokenGive,
		uint256 amountGive,
		uint256 timestamp
		);
	event Cancel(
		uint256 id,
		address user,
		address tokenGet,
		uint256 amountGet,
		address tokenGive,
		uint256 amountGive,
		uint256 timestamp
		);
	event Trade(
		uint256 id,
		address user,
		address tokenGet,
		uint256 amountGet,
		address tokenGive,
		uint256 amountGive,
		address userFill,
		uint256 timestamp
		);

	//Structs
	//Model the Order
	struct _Order {
		uint256 id;
		address user; 
		address tokenGet;
		uint256 amountGet;
		address tokenGive;
		uint256 amountGive;
		uint256 timestamp;
	}

	constructor (address _feeAccount, uint _feePercent) public {
		feeAccount = _feeAccount;
		feePercent = _feePercent;
	}

	//Fallback: revert transaction if Ether is sent to the smart contract
	function () external {
		revert();
	}


	function depositEther() payable public {

		tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
		emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);

	}

	function withdrawEther(uint _amount) public {
		require(tokens[ETHER][msg.sender] >= _amount);
		tokens[ETHER][msg.sender] = tokens [ETHER][msg.sender].sub(_amount);
		msg.sender.transfer(_amount);
		emit Withdraw (ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
	}

	function depositToken(address _token, uint _amount) public {
		//Dont allow Ether deposits
		require(_token != ETHER);

		require (Token(_token).transferFrom(msg.sender, address(this), _amount));
		tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
		emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function withdrawToken(address _token, uint256 _amount) public {
		require(_token != ETHER);
		require(tokens[_token][msg.sender] >= _amount);
		tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
		require(Token(_token).transfer(msg.sender, _amount));
		emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function balanceOf (address _token, address _user) public view returns (uint256){
		return tokens[_token][_user];
	}

	function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {

		orderCount = orderCount.add(1);
		orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
		emit Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
	}

	function cancelOrder (uint256 _id) public {
		_Order storage _order = orders[_id]; //fetch order from mapping 

		require(address(_order.user) == msg.sender); //Make sure the order is "my order"
		require(_order.id == _id); //order must exist 
		orderCancelled[_id] = true;
		emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
	}

	function fillOrder (uint256 _id) public {
		
		require(_id > 0 && _id <= orderCount);
		require (!orderFilled[_id]);
		require (!orderCancelled[_id]);

		_Order storage _order = orders[_id];
		_trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
		orderFilled[_order.id] = true;



	}

	function _trade (uint256 _orderId, address _user, address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {
		// This function executes trade, charge fees, marks order as filled, and emits trade event
		uint256 _feeAmount = _amountGet.mul(feePercent).div(100); //calculate fee

		//Execute Trade with Fees 
		tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
		tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);
		tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(_feeAmount);
		tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
		tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive);

		emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, now);



	}

}


//To Do:
//Set Fee Account - done
//Deposit Eth - done
//Withdraw Eth - done
//Deposit Tokens - done
//Withdraw Tokens -done
//Check balances - done
//Make Order - done
//Cancel Order - done
//Fill Order - done
//Charge Fees - done





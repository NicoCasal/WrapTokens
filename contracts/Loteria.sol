// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/ERC20.sol";
import "contracts/wrapERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Loteria is ERC20, Ownable {
    //========================================
    //===========Token Managment==============
    //========================================

    //contract address NFT proyect
    address public nft;

    //constructor
    constructor() ERC20("Loteria", "JA") {
        mint(address(this), 1000);
        nft = address(new mainERC721());
    }

    //lottery winner
    address public winner;

    //registration
    mapping(address => address) public usuario_contract;

    //Token Priece
    function precioTokens(uint256 _numTokens) internal pure returns (uint256) {
        return _numTokens * (1 ether);
    }

    // user token balance view
    function balanceTokens(address _account) public view returns (uint256) {
        return balanceOf(_account);
    }

    //smart contract token balance view
    function balanceTokensSC() public view returns (uint256) {
        return balanceOf(address(this));
    }

    //smart contract ethers balance view
    function blanceEthersSC() public view returns (uint256) {
        return address(this).balance / 10 ** 18;
    }

    //ERC20 Token generator (only owner)
    function mint(uint256 _amount) public onlyOwner {
        mint(address(this), _amount);
    }

    //user reggit
    function registrar() internal {
        address addr_personal_contract = address(
            new boletosNFT(msg.sender, address(this), nft)
        );
        usuario_contract[msg.sender] = addr_personal_contract;
    }

    //user info
    function usersInfo(address _account) public view returns (address) {
        return usuario_contract[_account];
    }

    //tokens buy ERC20
    function compraTokens(uint256 _numTokens) public payable {
        //user reggit
        if (usuario_contract[msg.sender] == address(0)) {
            registrar();
        }
        //establecer el precio de los token a comprar
        uint256 coste = precioTokens(_numTokens);
        require(msg.value >= coste, "compra menos tokens o paga mas ETH");

        //obtencion del numero de tokens disponible
        uint256 balance = balanceTokensSC();
        require(_numTokens <= balance, "compra menos tokens");

        //devolucion del dinero sobrante
        uint256 returnValue = msg.value - coste;

        //el smart contrar devuelve la cantidad restante
        payable(msg.sender).transfer(returnValue);

        //envio de los tokens al usurio
        _transfer(address(this), msg.sender, _numTokens);
    }

    //cambiar a funcion de burnear
    //devolucion de tokens al smart contract
    function devolverTokens(uint _numTokens) public payable {
        //el numero de tokens debe ser mayor a 0
        require(_numTokens > 0, "necesitas devolver un numero mayor a 0");

        //el uusuario debe acreditar el numero de token  que quiere devolver
        require(
            _numTokens <= balanceTokens(msg.sender),
            "no tienes los tokens que deceas devolver"
        );

        //el usurio transfiere los tokens al smart contract
        _transfer(msg.sender, address(this), _numTokens);

        //el smart contract envia los eth al usuario
        payable(msg.sender).transfer(precioTokens(_numTokens));
    }

    //=======================================//
    //=========gestion de la loteria=========//
    //=======================================//

    //precio del boleto de la loteria (en tokens ERC-20)
    uint public precioBoleto = 1;
    //relacion: persona que compra los boletos -> el numero de los boletos
    mapping(address => uint[]) idPersona_boletos;
    //relacion: boleto -> winner
    mapping(uint => address) ADNBoleto;
    //numero aleatorio
    uint randNonce = 0;
    //boletos de la loteria generados
    uint[] boletosComprados;

    //compra de boletos de loteria
    function compraBoletos(uint _numBoletos) public {
        //precio total de los boletos a comprar
        uint precioTotal = _numBoletos * precioBoleto;
        //verificacion de los tekens del usuario
        require(
            precioTotal <= balanceTokens(msg.sender),
            "no tienes tokens suficientes"
        );
        //transferencia de tojens del usuario al smart contract
        _transfer(msg.sender, address(this), precioTotal);

        /*recoge la marca de tiempo (block.timestamp), msg.sender y un Nonce
    (un numero que solo se ultilixa una vez, para que no ejecutemos dos veces la misma
    funcion de hash con lso msimos parametros de entrada) enincremento.
    se utiliza keccak256 para convetir estas entradas a un hash aleatorio,
    convertir ese hash a un uint y luego utilizmaos % 10000 para tomar los ultimos 4 digitos, 
    dando un valor aleatorio entre 0 - 9999. */
        for (uint i = 0; i < _numBoletos; i++) {
            uint random = uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % 10000;
            randNonce++;
            //almacenamiento de los datos del boleto enlazados al usuario
            idPersona_boletos[msg.sender].push(random);
            //almacenamiento de los datos de los boletos
            boletosComprados.push(random);
            //asigancion del adn del boleto para la generacion de un winner
            ADNBoleto[random] = msg.sender;
            //creacion de un nuevo nft para el numero de boleto
            boletosNFT(usuario_contract[msg.sender]).mintBoletos(
                msg.sender,
                random
            );
        }
    }

    //visualizacion de los boletos del usuario
    function tusBoletos(
        address _propietario
    ) public view returns (uint[] memory) {
        return idPersona_boletos[_propietario];
    }

    //generacion del winner de la loteria
    function generarwinner() public onlyOwner {
        //declaracion de longitud de array
        uint longitud = boletosComprados.length;
        //verificacion de compra de almenos 1 boleto
        require(longitud > 0, "no hay boletos comprados");
        //eleccion aleatoria de un numero entre: [0 - longitud]
        uint random = uint(
            uint(keccak256(abi.encodePacked(block.timestamp))) % longitud
        );
        //seleccion de un numero aleatorio
        uint eleccion = boletosComprados[random];
        //direccion del winner de la loteria
        winner = ADNBoleto[eleccion];
        // envio del 95% del premio de la loteria al winner
        payable(winner).transfer((address(this).balance * 95) / 100);
        //envio del 5% del premio de loteria al owner
        payable(owner()).transfer((address(this).balance * 5) / 100);
    }
}

//NFTs smart contract
contract mainERC721 is ERC721 {
    address public direccionLoteria;

    constructor() ERC721("Loteria", "STE") {
        direccionLoteria = msg.sender;
    }

    //nft creation
    function safeMint(address _propietario, uint256 _boleto) public {
        require(
            msg.sender == Loteria(direccionLoteria).usersInfo(_propietario),
            "no tienes permisos para ejecutar esta funcion"
        );
        _safeMint(_propietario, _boleto);
    }
}

contract boletosNFT {
    //data structure
    struct Owner {
        address propietario;
        address contratoPadre;
        address contratoNFT;
        address contratoUsuario;
    }

    //Owner data structure
    Owner public propietario;

    //constructor (son)
    constructor(
        address _propietario,
        address _contratoPadre,
        address _contratoNFT
    ) {
        propietario = Owner(
            _propietario,
            _contratoPadre,
            _contratoNFT,
            address(this)
        );
    }

    //conversion de los numeros de los boletos de loteria

    function mintBoletos(address _propietario, uint _boleto) public {
        require(
            msg.sender == propietario.contratoPadre,
            "you dont have permission"
        );
        mainERC721(propietario.contratoNFT).safeMint(_propietario, _boleto);
    }
}

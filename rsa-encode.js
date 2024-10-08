import NodeRSA from 'encrypt-rsa';


const modulusLength = 2048;
const nodeRSA = new NodeRSA(undefined, undefined, modulusLength);

const { publicKey, privateKey } =
  nodeRSA.createPrivateAndPublicKeys(modulusLength);
console.log("Public Key:", publicKey);
console.log("Private Key:", privateKey);

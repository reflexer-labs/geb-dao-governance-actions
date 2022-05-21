const { ethers } = require("ethers");

let ABI = ["function " + process.argv[2]]
let iface = new ethers.utils.Interface(ABI)

console.log(iface.encodeFunctionData(
    process.argv[2].split("(")[0],
    process.argv.slice(3)
))
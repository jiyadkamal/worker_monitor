const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET || "secretkey";

const auth = (req, res, next) => {
    try {
        const authHeader = req.header("Authorization");

        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({ message: "No token, authorization denied" });
        }

        const token = authHeader.replace("Bearer ", "");
        const decoded = jwt.verify(token, JWT_SECRET);

        req.user = { id: decoded.id };
        next();
    } catch (error) {
        return res.status(401).json({ message: "Token is not valid" });
    }
};

module.exports = auth;

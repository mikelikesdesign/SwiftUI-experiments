import { motion } from 'framer-motion';

function Chart({ data }) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5 }}
    >
      {/* Existing chart code */}
    </motion.div>
  );
}
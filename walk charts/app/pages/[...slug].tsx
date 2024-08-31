import { motion } from 'framer-motion';

// ... existing imports ...

const Page = ({ params }) => {
  // ... existing code ...

  return (
    <motion.div
      key={params.slug.join('/')}
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      transition={{ duration: 0.3 }}
    >
      {/* Existing page content */}
    </motion.div>
  );
};

export default Page;
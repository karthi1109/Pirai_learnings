import React from 'react';
import HeroSection from '../../HeroSection';
import { homeObjFour } from './Data';
import Pricing from '../../Pricing';

function Services() {
  return (
    <>
      <Pricing />
      <HeroSection {...homeObjFour} />
    </>
  );
}

export default Services;
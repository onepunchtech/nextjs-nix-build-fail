/** Add your relevant code here for the issue to reproduce */
import Image from 'next/image';
import tux from '../public/Tux.png'


export default function Home() {
  return (
    <div>
      foobar
      <Image  src={tux} alt="linux penguin" width="200" height="300" />
    </div>
  )
}

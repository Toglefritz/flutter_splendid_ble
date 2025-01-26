import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'Comprehensive BLE Capabilities',
    Image: 'img/features.png',
    description: (
      <>
        Flutter Splendid BLE provides robust Bluetooth Low Energy (BLE) functionality,
        including scanning for devices, managing connections, reading and writing characteristics,
        and subscribing to notifications or indications from peripherals.
      </>
    ),
  },
  {
    title: 'Cross-Platform Compatibility',
    Image: 'img/cross-platform.png',
    description: (
      <>
        Designed for both iOS and Android, this plugin simplifies the integration of BLE
        features by handling platform-specific requirements and configurations seamlessly.
      </>
    ),
  },
  {
    title: 'Developer-Friendly Design',
    Image: 'img/development.png',
    description: (
      <>
        Built with Flutter and Dart best practices in mind, Flutter Splendid BLE ensures smooth integration,
        detailed documentation, and tools that developers at any level can leverage effectively.
      </>
    ),
  },
];

function Feature({Image, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center padding-horiz--md">
        <img src={Image} alt={title} width="200"/>
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

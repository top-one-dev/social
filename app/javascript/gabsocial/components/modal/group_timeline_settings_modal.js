import { defineMessages, injectIntl } from 'react-intl'
import ImmutablePureComponent from 'react-immutable-pure-component'
import Button from '../button'
import Text from '../text'
import ModalLayout from './modal_layout'

const messages = defineMessages({
  title: { id: 'promo.goji_pro', defaultMessage: 'Upgrade to GojiPRO' },
  text: { id: 'pro_upgrade_modal.text', defaultMessage: 'Goji.live is fully funded by people like you. Please consider supporting us on our mission to defend free expression online for all people.' },
  benefits: { id: 'pro_upgrade_modal.benefits', defaultMessage: 'Here are just some of the benefits that thousands of GojiPro/GojiProPlus members receive:' },
})

export default
@injectIntl
class HomeTimelineSettingsModal extends ImmutablePureComponent {

  static propTypes = {
    intl: PropTypes.object.isRequired,
  }

  render() {
    const { intl } = this.props

    return (
      <div>
        <Text>
          {intl.formatMessage(messages.text)}
        </Text>
        <Text>
          {intl.formatMessage(messages.benefits)}
        </Text>

        <div className={[_s.default, _s.my10].join(' ')}>
          <Text>• Schedule Posts</Text>
          <Text>• Get Verified</Text>
          <Text>• Create Groups</Text>
          <Text>• Larger Video and Image Uploads</Text>
          <Text>• Receive the PRO Badge</Text>
          <Text>• Remove in-feed promotions</Text>
        </div>

        <Button
          backgroundColor='brand'
          color='white'
          icon='pro'
          href=' https://goji.network'
          className={_s.justifyContentCenter}
          iconClassName={[_s.mr5, _s.fillWhite].join(' ')}
        >
          <Text color='inherit' weight='bold' align='center'>
            {intl.formatMessage(messages.title)}
          </Text>
        </Button>

      </div>
    )
  }
}

import React from "react"
import PropTypes from "prop-types"
class Checkouts extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      data: null
    }
  }

  componentDidMount() {
    fetch(this.props.apiUrl)
      .then(response => response.json())
      .then(data => this.setState({ data }))
  }

  render () {
    return (
      <>
        Api Requested: {this.props.apiUrl}
        <div>
          Data Received:
          <pre>
            <code>
              {JSON.stringify(this.state.data)}
            </code>
          </pre>
        </div>
      </>
    );
  }
}

Checkouts.propTypes = {
  apiUrl: PropTypes.string
};
export default Checkouts
